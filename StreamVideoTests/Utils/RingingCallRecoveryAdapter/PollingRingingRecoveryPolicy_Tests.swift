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

    func test_defaultConfiguration_pollsAfterNineSeconds_everyFiveSeconds() {
        let options = VideoConfig().ringStatePolling

        XCTAssertEqual(options?.startAfter, 9)
        XCTAssertEqual(options?.interval, 5)
    }

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
                    .typeCallRejectedEvent(.dummy(
                        call: .dummy(session: mockCall.state.session),
                        callCid: mockCall.cId
                    ))
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

    func test_previousRingFailsWith404_newRing_keepsPolling() async throws {
        makeSubject(interval: 0.1, runsActions: false)
        startRing(sessionId: "old-session")
        let oldAction = try await subject.actionPublisher.nextValue(timeout: 1)
        let (release, continuation) = AsyncStream<Void>.makeStream()
        defer { continuation.finish() }
        let error = makeAPIError(statusCode: 404)
        mockCall.onUpdateRingState = {
            for await _ in release { break }
            throw error
        }
        let oldRequest = Task { try await oldAction() }
        await fulfilmentInMainActor { self.polledSessionIds == ["old-session"] }

        // Wait for the replacement's first action before failing the old one.
        startRing(sessionId: "new-session")
        _ = try await subject.actionPublisher.nextValue(timeout: 1)
        continuation.yield()
        _ = await oldRequest.result
        mockCall.onUpdateRingState = nil

        let nextAction = try await subject.actionPublisher.nextValue(timeout: 1)
        try await nextAction()

        XCTAssertEqual(polledSessionIds, ["old-session", "new-session"])
    }

    func test_queuedPoll_terminalFailure_skipsRequest() async throws {
        makeSubject(interval: 0.1, runsActions: false)
        startRing()
        // Hold emitted work, just as the serial queue does behind a slow fetch.
        let actions = try await subject.actionPublisher.collect(2).nextValue(timeout: 1)
        mockCall.stub(for: .updateRingState, with: makeAPIError(statusCode: 404))

        try? await actions[0]()
        try? await actions[1]()

        XCTAssertEqual(polledSessionIds.count, 1)
    }

    func test_queuedPoll_deadlinePassed_skipsRequest() async throws {
        makeSubject(runsActions: false)
        startRing(autoCancelTimeoutMs: 300)
        let action = try await subject.actionPublisher.nextValue(timeout: 1)
        // The call stays ringing; expiry alone must invalidate queued work.
        _ = try await DefaultTimer.publish(every: 0.3).nextValue(timeout: 1)

        try await action()

        XCTAssertTrue(polledSessionIds.isEmpty)
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
        interval: TimeInterval = 5,
        runsActions: Bool = true
    ) {
        subject = .init(
            mockStreamVideo,
            options: .init(startAfter: startAfter, interval: interval)
        )
        if runsActions {
            adapter = .init(mockStreamVideo, policies: [subject])
        }
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
