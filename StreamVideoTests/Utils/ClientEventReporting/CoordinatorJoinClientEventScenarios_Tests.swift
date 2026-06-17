//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CoordinatorJoinClientEventScenarios_Tests: XCTestCase, @unchecked Sendable {

    func test_authenticationFails_reportsCoordinatorJoinFailureWithRetryCount() async throws {
        let harness = ClientEventScenarioHarness()
        let subject = makeConnectingStage(harness: harness, reconnectAttempts: 3)

        try await assertTransition(
            subject,
            from: .idle,
            expectedTarget: .error
        ) { _ in }

        let trace = await harness.trace
        trace.assertCompleted(
            .coordinatorJoin,
            outcome: .failure,
            retryCount: 3
        )
        XCTAssertEqual(trace.begun(.coordinatorJoin).first?.details.joinReason, .firstAttempt)
    }

    func test_authenticationSucceedsAfterRetries_reportsCoordinatorJoinSuccessWithRetryCount(
    ) async throws {
        let harness = ClientEventScenarioHarness()
        let response = JoinCallResponse.dummy(
            call: .dummy(currentSessionId: "call-session-1")
        )
        harness.stack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((harness.stack.sfuStack.adapter, response))
        )
        harness.stack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )
        let subject = makeConnectingStage(harness: harness, reconnectAttempts: 2)

        try await assertTransition(
            subject,
            from: .idle,
            expectedTarget: .connected
        ) { _ in }

        let trace = await harness.trace
        trace.assertCompleted(
            .coordinatorJoin,
            outcome: .success,
            retryCount: 2
        )
        XCTAssertEqual(
            trace.completed(.coordinatorJoin).last?.details.callSessionId,
            "call-session-1"
        )
        XCTAssertEqual(trace.begun(.coordinatorJoin).first?.details.joinReason, .firstAttempt)
    }

    // MARK: - Private

    private func makeConnectingStage(
        harness: ClientEventScenarioHarness,
        reconnectAttempts: UInt32
    ) -> WebRTCCoordinator.StateMachine.Stage {
        var context = WebRTCCoordinator.StateMachine.Stage.Context(
            coordinator: harness.stack.coordinator,
            reconnectAttempts: reconnectAttempts
        )
        context.authenticator = harness.stack.webRTCAuthenticator
        return .connecting(
            context,
            create: true,
            options: nil,
            ring: false,
            notify: false
        )
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
