//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class HLSStatsAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var api: MockDefaultAPIEndpoints! = .init()
    private lazy var player: MockHLSPlayer! = .init()
    private var subject: HLSStatsAdapter!

    override func setUp() {
        super.setUp()
        api.stub(for: .reportHLSStats, with: ReportHLSStatsResponse(duration: "1ms"))
    }

    override func tearDown() async throws {
        await subject?.stopReporting()
        subject = nil
        player = nil
        api = nil
        try await super.tearDown()
    }

    // MARK: - start

    func test_start_beforeThePlayerPlays_sendsNothing() async {
        await makeSubject()

        await subject.startReporting()
        await wait(for: 0.2)

        XCTAssertTrue(api.hlsStatsReports.isEmpty)
    }

    func test_firstPlaying_sendsStartedOnce() async {
        await makeSubject()
        await subject.startReporting()

        player.simulate(.playing)
        player.simulate(.paused)
        player.simulate(.playing)

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        XCTAssertEqual(api.hlsStatsReports.first?.type, .started)
    }

    func test_playerAlreadyPlaying_whenReportingStarts_sendsStarted() async {
        player.simulate(.playing)
        await makeSubject()

        await subject.startReporting()

        await fulfillment { self.api.hlsStatsReports.first?.type == .started }
    }

    // MARK: - interval

    func test_interval_afterTheFirstPlay_sendsStats() async {
        await makeSubject(interval: 0.1)
        await subject.startReporting()

        player.simulate(.playing)

        await fulfillment { self.api.hlsStatsReports.filter { $0.type == .stats }.count >= 2 }
    }

    func test_interval_beforeTheFirstPlay_sendsNoStats() async {
        await makeSubject(interval: 0.05)
        await subject.startReporting()

        await wait(for: 0.4)

        XCTAssertTrue(api.hlsStatsReports.isEmpty)
    }

    func test_stop_cancelsTheInterval() async {
        await makeSubject(interval: 0.05)
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.contains { $0.type == .stats } }

        await subject.stopReporting()
        await fulfillment { self.api.hlsStatsReports.last?.type == .ended }
        let count = api.hlsStatsReports.count
        await wait(for: 0.4)

        XCTAssertEqual(api.hlsStatsReports.count, count)
    }

    func test_interval_whileAReportIsStillSending_doesNotQueueAnother() async {
        api.reportHLSStatsHandler = { try? await Task.sleep(nanoseconds: 500_000_000) }
        await makeSubject(interval: 0.05)
        await subject.startReporting()

        player.simulate(.playing)
        await wait(for: 0.4)

        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started])
    }

    // MARK: - stop

    func test_stop_afterPlaying_sendsEndedWithTheFinalStats() async {
        await makeSubject()
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }

        await subject.stopReporting()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .left)
        XCTAssertNotNil(api.hlsStatsReports.last?.stats)
        XCTAssertEqual(api.hlsStatsReports.last?.events?.map(\.type), ["first_frame"])
    }

    func test_stop_beforeTheFirstPlay_sendsNothing() async {
        await makeSubject()
        await subject.startReporting()

        await subject.stopReporting()
        await wait(for: 0.2)

        XCTAssertTrue(api.hlsStatsReports.isEmpty)
    }

    func test_play_afterStop_sendsNothing() async {
        await makeSubject()
        await subject.startReporting()
        await subject.stopReporting()

        player.simulate(.playing)
        await wait(for: 0.2)

        XCTAssertTrue(api.hlsStatsReports.isEmpty)
    }

    func test_stop_doesNotWaitForTheNetwork() async {
        api.reportHLSStatsHandler = { try? await Task.sleep(nanoseconds: 5_000_000_000) }
        await makeSubject()
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }

        let started = Date()
        await subject.stopReporting()

        XCTAssertLessThan(Date().timeIntervalSince(started), 2)
    }

    func test_publishCurrentSnapshot_afterStop_sendsNothingMore() async {
        await makeSubject()
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }
        await subject.stopReporting()
        await fulfillment { self.api.hlsStatsReports.last?.type == .ended }
        let count = api.hlsStatsReports.count

        await subject.publishCurrentSnapshot()
        await wait(for: 0.2)

        XCTAssertEqual(api.hlsStatsReports.count, count)
    }

    // MARK: - terminal errors

    private let failure = NSError(domain: "AVFoundationErrorDomain", code: -11800)

    @MainActor
    func test_itemFailsBeforePlaying_thenThePlayerGivesUp_sendsStartedThenEndedWithTheError() async {
        let item = MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        player.stubbedItem = item
        await makeSubject()
        await subject.startReporting()
        item.fail(with: failure)

        await subject.stopReporting(gaveUp: true)

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .error)
        XCTAssertEqual(api.hlsStatsReports.last?.errorCode, "AVFoundationErrorDomain -11800")
        XCTAssertEqual(api.hlsStatsReports.last?.events?.map(\.type), ["error"])
    }

    @MainActor
    func test_itemFailsBeforePlaying_thenTheCallLeaves_sendsStartedThenEndedWithTheError() async {
        let item = MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        player.stubbedItem = item
        await makeSubject()
        await subject.startReporting()
        item.fail(with: failure)

        await subject.stopReporting()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .error)
        XCTAssertEqual(api.hlsStatsReports.last?.errorCode, "AVFoundationErrorDomain -11800")
    }

    @MainActor
    func test_itemFailsThenRecovers_thenPlaysAndLeaves_sendsEndedWithoutAnError() async {
        let item = MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        player.stubbedItem = item
        await makeSubject()
        await subject.startReporting()
        item.fail(with: failure)
        item.simulate(status: .readyToPlay)
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }

        await subject.stopReporting()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .left)
        XCTAssertNil(api.hlsStatsReports.last?.errorCode)
    }

    @MainActor
    func test_itemFailsAfterPlaying_thenThePlayerGivesUp_sendsEndedWithTheErrorOnce() async {
        let item = MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        player.stubbedItem = item
        await makeSubject()
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }
        item.fail(with: failure)

        await subject.stopReporting(gaveUp: true)
        await subject.stopReporting()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        await wait(for: 0.2)
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .error)
        XCTAssertEqual(api.hlsStatsReports.last?.errorCode, "AVFoundationErrorDomain -11800")
    }

    @MainActor
    func test_playerGivesUpWithoutAnError_sendsEndedWithTheTimeoutCode() async {
        await makeSubject()
        await subject.startReporting()

        await subject.stopReporting(gaveUp: true)

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .error)
        XCTAssertEqual(api.hlsStatsReports.last?.errorCode, "load_timeout")
    }

    @MainActor
    func test_itemFailsAfterPlaying_thenTheCallLeaves_sendsEndedWithoutAnError() async {
        let item = MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        player.stubbedItem = item
        await makeSubject()
        await subject.startReporting()
        player.simulate(.playing)
        await fulfillment { self.api.hlsStatsReports.count == 1 }
        item.fail(with: failure)

        await subject.stopReporting()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .left)
        XCTAssertNil(api.hlsStatsReports.last?.errorCode)
    }

    // MARK: - Private Helpers

    private func makeSubject(interval: TimeInterval = 60) async {
        subject = HLSStatsAdapter(
            player: player,
            api: api,
            callType: "livestream",
            callId: "call-1",
            callSessionId: "session-1",
            unifiedSessionId: "unified-1",
            statsToken: "token-1",
            interval: interval,
            retryPolicy: .init(maxRetries: 2, delay: { _ in 0 })
        )
    }
}
