//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class PollingRingingRecoveryPolicy_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private var mockCall: MockCall! = .init(.dummy())
    private var adapter: RingingCallRecoveryAdapter!
    private var subject: PollingRingingRecoveryPolicy!

    override func tearDown() async throws {
        adapter = nil
        subject = nil
        mockCall = nil
        mockStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - Polling

    func test_callerRing_quietPeriodElapses_pollsCapturedSession() async {
        makeSubject()
        startRing(sessionId: "session-1")

        await fulfilmentInMainActor { self.polledSessionIds == ["session-1"] }
    }

    func test_calleeRing_quietPeriodElapses_doesNotPoll() async {
        makeSubject()
        startRing(createdBy: .dummy())

        await wait(for: 0.5)

        XCTAssertTrue(polledSessionIds.isEmpty)
    }

    func test_ringEventsKeepArriving_pollsOnlyAfterTheyStop() async {
        makeSubject(startAfter: 0.5)
        startRing()

        for _ in 0..<5 {
            await wait(for: 0.2)
            await mockCall.onEvent(
                .coordinatorEvent(
                    .typeCallRejectedEvent(.dummy(callCid: mockCall.cId))
                )
            )
        }
        XCTAssertTrue(polledSessionIds.isEmpty)

        await fulfilmentInMainActor { !self.polledSessionIds.isEmpty }
    }

    // MARK: - Stopping

    func test_ringTimesOut_stopsPolling() async {
        makeSubject(interval: 0.1)
        startRing(autoCancelTimeoutMs: 400)
        await assertPollingStops()
    }

    func test_ringWithoutAutoCancel_stopsAtMissedCallTimeout() async {
        makeSubject(interval: 0.1)
        startRing(autoCancelTimeoutMs: 0, missedCallTimeoutMs: 400)
        await assertPollingStops()
    }

    func test_pollFailsWith404_stopsPolling() async {
        mockCall.stub(for: .updateRingState, with: makeAPIError(statusCode: 404))
        makeSubject(interval: 0.2)
        startRing()
        await fulfilmentInMainActor { self.polledSessionIds.count == 1 }

        await wait(for: 0.6)

        XCTAssertEqual(polledSessionIds.count, 1)
    }

    // MARK: - Private Helpers

    private func assertPollingStops() async {
        await fulfilmentInMainActor { !self.polledSessionIds.isEmpty }

        await wait(for: 0.5)
        let pollCount = polledSessionIds.count
        await wait(for: 0.5)

        XCTAssertEqual(polledSessionIds.count, pollCount)
    }

    private var polledSessionIds: [String] {
        (mockCall.stubbedFunctionInput[.updateRingState] ?? []).compactMap {
            guard case let .updateRingState(callSessionId) = $0 else {
                return nil
            }
            return callSessionId
        }
    }

    private func makeSubject(
        startAfter: TimeInterval = 0.1,
        interval: TimeInterval = 5
    ) {
        subject = .init(
            mockStreamVideo,
            options: .init(startAfter: startAfter, interval: interval)
        )
        adapter = .init(policies: [subject])
    }

    private func startRing(
        createdBy: User? = nil,
        sessionId: String = "session-id",
        autoCancelTimeoutMs: Int = 30000,
        missedCallTimeoutMs: Int = 0
    ) {
        mockCall.state.createdBy = createdBy ?? mockStreamVideo.user
        mockCall.state.session = .dummy(id: sessionId)
        mockCall.state.settings = .dummy(
            ring: .dummy(
                autoCancelTimeoutMs: autoCancelTimeoutMs,
                missedCallTimeoutMs: missedCallTimeoutMs
            )
        )
        mockStreamVideo.state.ringingCall = mockCall
    }

    private func makeAPIError(statusCode: Int) -> APIError {
        APIError(
            code: 0,
            details: [],
            duration: "",
            message: "",
            moreInfo: "",
            statusCode: statusCode
        )
    }
}
