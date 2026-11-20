//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class HLSPlaybackTracker_Tests: XCTestCase, @unchecked Sendable {

    private actor Recorder: HLSStatsDelivering {
        private(set) var reports: [HLSStatsReport] = []

        func deliver(
            callType _: String,
            callId _: String,
            report: HLSStatsReport
        ) async throws {
            reports.append(report)
        }
    }

    private var recorder: Recorder!
    private var subject: HLSStatsAdapter!

    override func tearDown() async throws {
        if let subject {
            _ = await subject.stopReporting().value
        }
        subject = nil
        recorder = nil
        try await super.tearDown()
    }

    func test_start_sendsStarted() async {
        await makeSubject()

        await subject.startReporting()

        let type = await recorder.reports.first?.type
        XCTAssertEqual(type, "started")
    }

    func test_stallThenPlaying_reportsTheStallAndTheFirstFrame() async {
        await makeSubject()
        await subject.startReporting()

        await subject.recordTimeControlStatus(
            .waitingToPlayAtSpecifiedRate,
            waitingReason: .toMinimizeStalls
        )
        await subject.recordTimeControlStatus(.playing, waitingReason: nil)
        await subject.publishCurrentSnapshot()

        let events = await recorder.reports.last?.events.map(\.type)
        XCTAssertEqual(events, ["stall_start", "stall_end", "first_frame"])
        let stallCount = await recorder.reports.last?.stats?.stallCount
        XCTAssertEqual(stallCount, 1)
    }

    func test_stop_afterAFailure_sendsEndedWithTheError() async {
        await makeSubject()
        await subject.startReporting()
        await subject.recordPlaybackFailure(
            NSError(domain: "AVFoundationErrorDomain", code: -11800)
        )

        await subject.stopReporting().value

        let report = await recorder.reports.last
        XCTAssertEqual(report?.type, "ended")
        XCTAssertEqual(report?.endReason, "error")
        XCTAssertEqual(report?.errorCode, "AVFoundationErrorDomain -11800")
    }

    func test_reportNow_afterStop_sendsNothingMore() async {
        await makeSubject()
        await subject.startReporting()
        await subject.stopReporting().value
        let count = await recorder.reports.count

        await subject.publishCurrentSnapshot()

        let countAfter = await recorder.reports.count
        XCTAssertEqual(countAfter, count)
    }

    private func makeSubject() async {
        recorder = Recorder()
        subject = HLSStatsAdapter(
            player: AVPlayer(),
            callType: "livestream",
            callId: "call-1",
            callSessionId: "session-1",
            unifiedSessionId: "unified-1",
            interval: 60,
            delivery: recorder
        )
    }
}
