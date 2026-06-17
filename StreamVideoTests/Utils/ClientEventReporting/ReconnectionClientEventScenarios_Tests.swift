//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ReconnectionClientEventScenarios_Tests: XCTestCase, @unchecked Sendable {

    func test_sfuErrorFast_transitionsToDisconnectedWithFastStrategy() async throws {
        let harness = ClientEventScenarioHarness()

        try await assertJoinedTransition(
            harness: harness,
            expectedTarget: .disconnected,
            trigger: {
                harness.stack.sfuStack.receiveEvent(
                    .sfuEvent(
                        .error(
                            SFUEventFactory.error(
                                code: .internalServerError,
                                reconnectStrategy: .fast
                            )
                        )
                    )
                )
                harness.stack.sfuStack.setConnectionState(to: .disconnected(source: .noPongReceived))
            }
        ) { target in
            guard case .fast = target.context.reconnectionStrategy else {
                return XCTFail("Expected fast reconnection strategy.")
            }
        }
    }

    func test_sfuErrorRejoin_transitionsToDisconnectedWithRejoinStrategy() async throws {
        let harness = ClientEventScenarioHarness()

        try await assertJoinedTransition(
            harness: harness,
            expectedTarget: .disconnected,
            trigger: {
                let error = SFUEventFactory.error(
                    code: .internalServerError,
                    reconnectStrategy: .rejoin
                )
                harness.stack.sfuStack.receiveEvent(
                    .sfuEvent(.error(error))
                )
                harness.stack.sfuStack.setConnectionState(
                    to: .disconnected(
                        source: .serverInitiated(error: .init(with: error.error))
                    )
                )
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .rejoin)
        }
    }

    func test_sfuErrorMigrate_transitionsToDisconnectedWithMigrateStrategy() async throws {
        let harness = ClientEventScenarioHarness()

        try await assertJoinedTransition(
            harness: harness,
            expectedTarget: .disconnected,
            trigger: {
                harness.stack.sfuStack.receiveEvent(
                    .sfuEvent(
                        .error(
                            SFUEventFactory.error(
                                code: .internalServerError,
                                reconnectStrategy: .migrate
                            )
                        )
                    )
                )
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .migrate)
        }
    }

    func test_goAway_transitionsToDisconnectedWithMigrateStrategy() async throws {
        let harness = ClientEventScenarioHarness()

        try await assertJoinedTransition(
            harness: harness,
            expectedTarget: .disconnected,
            trigger: {
                harness.stack.sfuStack.receiveEvent(
                    .sfuEvent(.goAway(SFUEventFactory.goAway()))
                )
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .migrate)
        }
    }

    func test_sfuErrorDisconnect_transitionsToLeaving() async throws {
        let harness = ClientEventScenarioHarness()

        try await assertJoinedTransition(
            harness: harness,
            expectedTarget: .leaving,
            trigger: {
                harness.stack.sfuStack.receiveEvent(
                    .sfuEvent(
                        .error(
                            SFUEventFactory.error(
                                code: .internalServerError,
                                reconnectStrategy: .disconnect
                            )
                        )
                    )
                )
            }
        ) { _ in }
    }

    func test_migration_startsNewJoinAttempt() async throws {
        let harness = ClientEventScenarioHarness()
        await harness.installSFUAdapter()
        let initialJoinAttemptId = await harness.stack.clientEventReporter.joinAttemptId
        let subject = WebRTCCoordinator.StateMachine.Stage.migrating(
            .init(
                coordinator: harness.stack.coordinator,
                currentSFU: "sfu-1"
            )
        )

        try await assertTransition(
            subject,
            from: .disconnected,
            expectedTarget: .migrated
        ) { _ in }

        let trace = await harness.trace
        XCTAssertEqual(trace.joinInitiatedDetails.count, 1)
        XCTAssertEqual(trace.joinInitiatedDetails.first?.coordinatorConnectId, subject.context.coordinatorConnectId)
        let currentJoinAttemptId = await harness.stack.clientEventReporter.joinAttemptId
        XCTAssertNotEqual(
            currentJoinAttemptId,
            initialJoinAttemptId
        )
    }

    // MARK: - Private

    private func assertJoinedTransition(
        harness: ClientEventScenarioHarness,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        trigger: @escaping @Sendable () -> Void,
        validator: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        await harness.installSFUAdapter()
        let subject = WebRTCCoordinator.StateMachine.Stage.joined(
            .init(coordinator: harness.stack.coordinator)
        )
        try await assertTransition(
            subject,
            from: .joining,
            expectedTarget: expectedTarget,
            trigger: trigger,
            validator: validator,
            file: file,
            line: line
        )
    }

    private func assertTransition(
        _ subject: WebRTCCoordinator.StateMachine.Stage,
        from previousStageId: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        trigger: (@Sendable () -> Void)? = nil,
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
        if let trigger {
            try await Task.sleep(nanoseconds: 150_000_000)
            trigger()
        }
        await fulfillment(of: [expectation], timeout: defaultTimeout)
    }
}
