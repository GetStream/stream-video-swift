//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WSJoinClientEventScenarios_Tests: XCTestCase, @unchecked Sendable {

    func test_joinResponseTimeout_reportsWSJoinFailureWithRetryCount() async throws {
        let previousTimeout = WebRTCConfiguration.timeout
        WebRTCConfiguration.timeout.join = 0.1
        defer { WebRTCConfiguration.timeout = previousTimeout }

        let harness = ClientEventScenarioHarness()
        let subject = try await makeJoiningStage(
            harness: harness,
            reconnectAttempts: 0,
            coordinatorJoinAttemptCount: 2
        )
        subject.context.joinResponseHandler = PassthroughSubject<JoinCallResponse, Error>()
        try await assertTransition(
            subject,
            from: .connected,
            expectedTarget: .error
        ) { _ in }

        let trace = await harness.trace
        trace.assertCompleted(
            .wsJoin,
            outcome: .failure,
            retryCount: 2,
            failureCode: ClientEventFailureCode.requestTimeout.rawValue
        )
    }

    func test_joinResponseTimeout_whenJoinCompletionIsNotPending_transitionsToDisconnected(
    ) async throws {
        let previousTimeout = WebRTCConfiguration.timeout
        WebRTCConfiguration.timeout.join = 0.1
        defer { WebRTCConfiguration.timeout = previousTimeout }

        let harness = ClientEventScenarioHarness()
        let subject = try await makeJoiningStage(
            harness: harness,
            reconnectAttempts: 1,
            coordinatorJoinAttemptCount: 2
        )

        try await assertTransition(
            subject,
            from: .connected,
            expectedTarget: .disconnected
        ) { _ in }

        let trace = await harness.trace
        trace.assertCompleted(
            .wsJoin,
            outcome: .failure,
            retryCount: 1,
            failureCode: ClientEventFailureCode.requestTimeout.rawValue
        )
    }

    func test_joinResponseAfterRetries_reportsWSJoinSuccessWithRetryCount() async throws {
        let harness = ClientEventScenarioHarness()
        let subject = try await makeJoiningStage(harness: harness, reconnectAttempts: 2)

        let cancellable = receiveJoinResponse(harness)
        try await assertTransition(
            subject,
            from: .connected,
            expectedTarget: .joined
        ) { _ in }
        cancellable.cancel()

        let trace = await harness.trace
        trace.assertCompleted(.wsJoin, outcome: .success, retryCount: 2)
    }

    func test_fastReconnect_whenSFUIsConnected_doesNotReportWSJoin() async throws {
        let harness = ClientEventScenarioHarness()
        harness.stack.sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let subject = try await makeJoiningStage(harness: harness, reconnectAttempts: 1)

        let cancellable = receiveJoinResponse(harness)
        try await assertTransition(
            subject,
            from: .fastReconnected,
            expectedTarget: .joined
        ) { _ in }
        cancellable.cancel()

        let trace = await harness.trace
        trace.assertNotReported(.wsJoin)
    }

    func test_fastReconnect_whenSFUIsNotConnected_reportsWSJoinWithExistingJoinAttemptId(
    ) async throws {
        let harness = ClientEventScenarioHarness()
        let joinAttemptId = await harness.stack.clientEventReporter.joinAttemptId
        let subject = try await makeJoiningStage(harness: harness, reconnectAttempts: 1)

        let cancellable = receiveJoinResponse(harness)
        try await assertTransition(
            subject,
            from: .fastReconnected,
            expectedTarget: .joined
        ) { _ in }
        cancellable.cancel()

        let trace = await harness.trace
        trace.assertCompleted(.wsJoin, outcome: .success, retryCount: 1)
        XCTAssertEqual(trace.begun(.wsJoin).first?.attempt.joinAttemptId, joinAttemptId)
        XCTAssertTrue(trace.joinInitiatedDetails.isEmpty)
    }

    // MARK: - Private

    private func makeJoiningStage(
        harness: ClientEventScenarioHarness,
        reconnectAttempts: UInt32,
        coordinatorJoinAttemptCount: Int = 0
    ) async throws -> WebRTCCoordinator.StateMachine.Stage {
        await harness.installSFUAdapter()
        harness.stack.webRTCAuthenticator.stub(
            for: .waitForConnect,
            with: Result<Void, Error>.success(())
        )
        var context = WebRTCCoordinator.StateMachine.Stage.Context(
            coordinator: harness.stack.coordinator,
            reconnectAttempts: reconnectAttempts,
            currentSFU: "sfu-1"
        )
        context.authenticator = harness.stack.webRTCAuthenticator
        context.coordinatorJoinAttemptCount = coordinatorJoinAttemptCount
        context.initialJoinCallResponse = .dummy(
            call: .dummy(currentSessionId: "call-session-1")
        )
        return .joining(context)
    }

    private func receiveJoinResponse(
        _ harness: ClientEventScenarioHarness
    ) -> AnyCancellable {
        Foundation
            .Timer
            .publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { _ in harness.sendJoinResponse(SFUEventFactory.joinResponse()) }
    }

    private func assertTransition(
        _ subject: WebRTCCoordinator.StateMachine.Stage,
        from previousStageId: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        validator: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let expectation = expectation(description: "Transition to \(expectedTarget)")
        subject.transition = { target in
            guard target.id == expectedTarget else { return }
            Task {
                do {
                    try await validator(target)
                    expectation.fulfill()
                } catch {
                    XCTFail("\(error)", file: file, line: line)
                }
            }
        }

        _ = subject.transition(from: .init(id: previousStageId, context: subject.context))
        await fulfillment(of: [expectation], timeout: defaultTimeout)
    }
}
