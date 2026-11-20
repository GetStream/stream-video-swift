//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class HLSPlaybackReporter_Tests: XCTestCase, @unchecked Sendable {

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

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private lazy var recorder: Recorder! = .init()
    private lazy var subject: HLSStatsReporter! = .init(
        callType: "livestream",
        callId: "call-1",
        callSessionId: "session-1",
        unifiedSessionId: "unified-1",
        delivery: recorder,
        now: { [now] in now }
    )

    override func tearDown() async throws {
        subject = nil
        recorder = nil
        try await super.tearDown()
    }

    func test_start_sendsStartedWithAStableUserSession() async {
        await subject.reportPlaybackStarted()

        let report = await recorder.reports.first
        XCTAssertEqual(report?.type, "started")
        XCTAssertEqual(report?.callSessionId, "session-1")
        XCTAssertEqual(report?.unifiedSessionId, "unified-1")
        XCTAssertEqual(report?.userSessionId.isEmpty, false)
        XCTAssertEqual(report?.timestamp, 1_700_000_000_000)
        XCTAssertEqual(report?.sdk, SystemEnvironment.sdkName)
        XCTAssertEqual(report?.sdkVersion, SystemEnvironment.version)
        XCTAssertNil(report?.endReason)
    }

    func test_stats_keepsTheUserSessionAndSendsTheSnapshot() async {
        await subject.reportPlaybackStarted()
        let userSessionId = await recorder.reports.first?.userSessionId

        await subject.reportPlaybackStats(
            stats: HLSPlaybackStats(
                watchDurationMs: 4000,
                stallCount: 1,
                stallDurationMs: 800,
                maxStallDurationMs: 800,
                droppedFrames: 3,
                bitrateKbps: 900,
                bufferLengthMs: 2000,
                liveLatencyMs: 6000,
                width: 1280,
                height: 720
            ),
            events: [
                HLSStatsEvent(type: "stall_start", timestamp: 1_700_000_000_100, data: [:])
            ]
        )

        let reports = await recorder.reports
        let report = reports.last
        XCTAssertEqual(reports.count, 2)
        XCTAssertEqual(report?.type, "stats")
        XCTAssertEqual(report?.userSessionId, userSessionId)
        XCTAssertEqual(report?.stats?.watchDurationMs, 4000)
        XCTAssertEqual(report?.stats?.stallCount, 1)
        XCTAssertEqual(report?.stats?.bitrateKbps, 900)
        XCTAssertEqual(report?.events.map(\.type), ["stall_start"])
    }

    func test_stop_withAnError_sendsEnded() async {
        await subject.reportPlaybackStarted()

        await subject.reportPlaybackEnded(errorCode: "AVFoundationErrorDomain -11800")

        let report = await recorder.reports.last
        XCTAssertEqual(report?.type, "ended")
        XCTAssertEqual(report?.endReason, "error")
        XCTAssertEqual(report?.errorCode, "AVFoundationErrorDomain -11800")
    }

    func test_stop_withoutAnError_sendsLeft() async {
        await subject.reportPlaybackStarted()

        await subject.reportPlaybackEnded(errorCode: nil)

        let report = await recorder.reports.last
        XCTAssertEqual(report?.endReason, "left")
        XCTAssertNil(report?.errorCode)
    }

    func test_eventsNamedStarted_areOmitted() async {
        await subject.reportPlaybackStats(
            stats: HLSPlaybackStats(),
            events: [
                HLSStatsEvent(type: "started", timestamp: 1, data: [:]),
                HLSStatsEvent(type: "stall_end", timestamp: 2, data: [:])
            ]
        )

        let types = await recorder.reports.last?.events.map(\.type)
        XCTAssertEqual(types, ["stall_end"])
    }
}
