//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class HLSStatsReporter_Tests: XCTestCase, @unchecked Sendable {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private lazy var api: MockDefaultAPIEndpoints! = .init()
    private lazy var subject: HLSStatsReporter! = makeSubject()

    override func setUp() {
        super.setUp()
        api.stub(for: .reportHLSStats, with: ReportHLSStatsResponse(duration: "1ms"))
    }

    override func tearDown() async throws {
        subject = nil
        api = nil
        try await super.tearDown()
    }

    // MARK: - content

    func test_started_hasAStableUserSessionAndTheClientDetails() async {
        subject.reportPlaybackStarted()

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        let report = api.hlsStatsReports.first
        XCTAssertEqual(report?.type, .started)
        XCTAssertEqual(report?.callSessionId, "session-1")
        XCTAssertEqual(report?.unifiedSessionId, "unified-1")
        XCTAssertEqual(report?.userSessionId.isEmpty, false)
        XCTAssertEqual(report?.timestamp, 1_700_000_000_000)
        XCTAssertEqual(report?.sdk, SystemEnvironment.sdkName)
        XCTAssertEqual(report?.sdkVersion, SystemEnvironment.version)
        XCTAssertNil(report?.endReason)
    }

    func test_sdkAndSdkVersion_areCutToTheBackendLimit() async {
        subject = makeSubject(
            sdk: String(repeating: "s", count: 80),
            sdkVersion: String(repeating: "v", count: 80)
        )

        subject.reportPlaybackStarted()

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        XCTAssertEqual(api.hlsStatsReports.first?.sdk?.count, 50)
        XCTAssertEqual(api.hlsStatsReports.first?.sdkVersion?.count, 50)
    }

    func test_everyReportType_carriesTheStatsTokenInItsJSON() async throws {
        subject.reportPlaybackStarted()
        subject.reportPlaybackStats(stats: .dummy(), events: [])
        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)

        await fulfillment { self.api.hlsStatsReports.count == 3 }
        let reports = api.hlsStatsReports
        XCTAssertEqual(reports.map(\.type), [.started, .stats, .ended])
        for report in reports {
            let data = try JSONEncoder.default.encode(report)
            let json = try XCTUnwrap(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            XCTAssertEqual(json["stats_token"] as? String, "token-1")
            XCTAssertEqual(json["unified_session_id"] as? String, "unified-1")
        }
    }

    func test_stats_keepsTheUserSessionAndSendsTheSnapshotAndEvents() async {
        subject.reportPlaybackStarted()
        await fulfillment { self.api.hlsStatsReports.count == 1 }
        subject.reportPlaybackStats(
            stats: .dummy(bitrateKbps: 900, stallCount: 1, watchDurationMs: 4000),
            events: [
                HLSPlayerEvent(
                    data: ["duration_ms": .number(800)],
                    timestamp: 1_700_000_000_100,
                    type: "stall_end"
                )
            ]
        )

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        let reports = api.hlsStatsReports
        XCTAssertEqual(reports.last?.userSessionId, reports.first?.userSessionId)
        XCTAssertEqual(reports.last?.stats?.watchDurationMs, 4000)
        XCTAssertEqual(reports.last?.stats?.stallCount, 1)
        XCTAssertEqual(reports.last?.stats?.bitrateKbps, 900)
        XCTAssertEqual(reports.last?.events?.first?.data, ["duration_ms": .number(800)])
    }

    func test_ended_carriesTheFinalStatsAndEvents() async {
        subject.reportPlaybackEnded(
            stats: .dummy(stallCount: 2, watchDurationMs: 9000),
            events: [HLSPlayerEvent(timestamp: 1, type: "stall_end")],
            errorCode: nil
        )

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        let report = api.hlsStatsReports.first
        XCTAssertEqual(report?.type, .ended)
        XCTAssertEqual(report?.stats?.stallCount, 2)
        XCTAssertEqual(report?.stats?.watchDurationMs, 9000)
        XCTAssertEqual(report?.events?.map(\.type), ["stall_end"])
    }

    func test_ended_whenDeliveryFails_retriesWithTheFinalStats() async {
        api.failHLSStats(withStatusCodes: [500])

        subject.reportPlaybackEnded(
            stats: .dummy(watchDurationMs: 9000),
            events: [HLSPlayerEvent(timestamp: 1, type: "stall_end")],
            errorCode: nil
        )

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.ended, .ended])
        XCTAssertEqual(api.hlsStatsReports.last?.stats?.watchDurationMs, 9000)
        XCTAssertEqual(api.hlsStatsReports.last?.events?.map(\.type), ["stall_end"])
    }

    func test_ended_withAnError_hasTheErrorReason() async {
        subject.reportPlaybackEnded(
            stats: .dummy(),
            events: [],
            errorCode: "AVFoundationErrorDomain -11800"
        )

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .error)
        XCTAssertEqual(api.hlsStatsReports.last?.errorCode, "AVFoundationErrorDomain -11800")
    }

    func test_ended_withoutAnError_hasTheLeftReason() async {
        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        XCTAssertEqual(api.hlsStatsReports.last?.endReason, .left)
        XCTAssertNil(api.hlsStatsReports.last?.errorCode)
    }

    // MARK: - events

    func test_events_beyondTheReportLimit_waitForTheNextReport() async {
        let events = (0..<150).map { HLSPlayerEvent(timestamp: $0, type: "quality_change") }

        subject.reportPlaybackStats(stats: .dummy(), events: events)
        subject.reportPlaybackStats(stats: .dummy(), events: [])

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        let reports = api.hlsStatsReports
        XCTAssertEqual(reports.first?.events?.map(\.timestamp), Array(0..<100))
        XCTAssertEqual(reports.last?.events?.map(\.timestamp), Array(100..<150))
    }

    func test_events_whenAStatsReportFails_ridesOnTheNextReport() async {
        api.failHLSStats(withStatusCodes: [500])

        subject.reportPlaybackStats(
            stats: .dummy(),
            events: [HLSPlayerEvent(timestamp: 1, type: "stall_start")]
        )
        subject.reportPlaybackStats(
            stats: .dummy(),
            events: [HLSPlayerEvent(timestamp: 2, type: "stall_end")]
        )

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.last?.events?.map(\.timestamp), [1, 2])
    }

    func test_events_whenAReportIsDelivered_arePartOfNoLaterReport() async {
        subject.reportPlaybackStats(
            stats: .dummy(),
            events: [HLSPlayerEvent(timestamp: 1, type: "stall_start")]
        )
        subject.reportPlaybackStats(stats: .dummy(), events: [])

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertNil(api.hlsStatsReports.last?.events)
    }

    func test_events_whenTheBackendRejectsTheReport_areDropped() async {
        api.failHLSStats(withStatusCodes: [400])

        subject.reportPlaybackStats(
            stats: .dummy(),
            events: [HLSPlayerEvent(timestamp: 1, type: "stall_start")]
        )
        subject.reportPlaybackStats(stats: .dummy(), events: [])

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertNil(api.hlsStatsReports.last?.events)
    }

    func test_events_beyondTheBuffer_dropTheOldest() async {
        let events = (0..<1100).map { HLSPlayerEvent(timestamp: $0, type: "quality_change") }

        subject.reportPlaybackStats(stats: .dummy(), events: events)

        await fulfillment { self.api.hlsStatsReports.count == 1 }
        XCTAssertEqual(api.hlsStatsReports.first?.events?.first?.timestamp, 100)
    }

    // MARK: - delivery

    func test_reports_areSentOneAtATimeInOrder() async {
        @Atomic var inFlight = 0
        @Atomic var peakInFlight = 0
        api.reportHLSStatsHandler = { [_inFlight, _peakInFlight] in
            _inFlight.mutate { $0 += 1 }
            _peakInFlight.mutate { $0 = max($0, _inFlight.wrappedValue) }
            try? await Task.sleep(nanoseconds: 50_000_000)
            _inFlight.mutate { $0 -= 1 }
        }

        subject.reportPlaybackStarted()
        subject.reportPlaybackStats(stats: .dummy(), events: [])
        subject.reportPlaybackStats(stats: .dummy(), events: [])
        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)

        await fulfillment { self.api.hlsStatsReports.count == 4 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .stats, .stats, .ended])
        XCTAssertEqual(peakInFlight, 1)
    }

    func test_ended_whenDeliveryKeepsFailing_givesUpAfterTheRetries() async {
        api.failHLSStats(withStatusCodes: [500, 500, 500, 500, 500])

        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)
        await fulfillment { !self.subject.isBusy }

        XCTAssertEqual(api.hlsStatsReports.count, 3)
    }

    func test_started_whenRateLimited_retries() async {
        api.failHLSStats(withStatusCodes: [429])

        subject.reportPlaybackStarted()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .started])
    }

    func test_started_whenTheRequestThrowsAnotherError_retries() async {
        failFirstAttempt(with: URLError(.notConnectedToInternet))

        subject.reportPlaybackStarted()

        await fulfillment { self.api.hlsStatsReports.count == 2 }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .started])
    }

    func test_stats_whenDeliveryFails_doesNotRetry() async {
        api.failHLSStats(withStatusCodes: [500])

        subject.reportPlaybackStats(stats: .dummy(), events: [])
        await fulfillment { !self.subject.isBusy }

        XCTAssertEqual(api.hlsStatsReports.count, 1)
    }

    func test_report_whenTheBackendRejectsIt_doesNotRetry() async {
        api.failHLSStats(withStatusCodes: [400])

        subject.reportPlaybackStarted()
        await fulfillment { !self.subject.isBusy }

        XCTAssertEqual(api.hlsStatsReports.count, 1)
        XCTAssertFalse(subject.isRejected)
    }

    func test_report_whenTheTokenIsForbidden_stopsEveryLaterReport() async {
        api.failHLSStats(withStatusCodes: [403])

        subject.reportPlaybackStarted()
        subject.reportPlaybackStats(stats: .dummy(), events: [])
        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)
        await fulfillment { !self.subject.isBusy }

        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started])
        XCTAssertTrue(subject.isRejected)
    }

    func test_stats_afterEnded_isNotSent() async {
        api.reportHLSStatsHandler = { try? await Task.sleep(nanoseconds: 50_000_000) }

        subject.reportPlaybackStarted()
        subject.reportPlaybackEnded(stats: .dummy(), events: [], errorCode: nil)
        subject.reportPlaybackStats(stats: .dummy(), events: [])

        await fulfillment { !self.subject.isBusy }
        XCTAssertEqual(api.hlsStatsReports.map(\.type), [.started, .ended])
    }

    // MARK: - Private Helpers

    /// Makes the first `reportHLSStats` call throw `error`. The mock records
    /// a call before the handler runs.
    private func failFirstAttempt(with error: Error) {
        api.reportHLSStatsHandler = { [weak api] in
            if api?.hlsStatsReports.count == 1 { throw error }
        }
    }

    private func makeSubject(
        sdk: String = SystemEnvironment.sdkName,
        sdkVersion: String = SystemEnvironment.version
    ) -> HLSStatsReporter {
        HLSStatsReporter(
            api: api,
            callType: "livestream",
            callId: "call-1",
            callSessionId: "session-1",
            unifiedSessionId: "unified-1",
            statsToken: "token-1",
            retryPolicy: .init(maxRetries: 2, delay: { _ in 0 }),
            currentDate: { [now] in now },
            sdk: sdk,
            sdkVersion: sdkVersion
        )
    }
}
