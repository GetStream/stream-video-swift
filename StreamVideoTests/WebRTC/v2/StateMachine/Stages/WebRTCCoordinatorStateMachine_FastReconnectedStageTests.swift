//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_FastReconnectedStageTests: XCTestCase, @unchecked Sendable {

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.fastReconnecting]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .fastReconnected(.init())

    override func tearDown() {
        allOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .fastReconnected)
    }

    // MARK: - transition

    func test_transition() {
        for nextStage in allOtherStages {
            if validStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage))
            }
        }
    }

    func test_transition_toFastReconnectedSucceeds_transitionsToJoining() async {
        await assertTransitionsWhileThrowing(
            from: .fastReconnecting,
            expectedTarget: .joining,
            error: ClientError(),
            expectedTransitionsChain: [.joining]
        )
    }

    func test_transition_toJoiningFails_transitionsToDisconnected() async {
        await assertTransitionsWhileThrowing(
            from: .fastReconnecting,
            expectedTarget: .disconnected,
            error: ClientError(),
            expectedTransitionsChain: [.joining, .disconnected]
        )
    }

    func test_transition_toJoiningAndDisconnectedFails_transitionsToError() async {
        await assertTransitionsWhileThrowing(
            from: .fastReconnecting,
            expectedTarget: .error,
            error: ClientError(),
            expectedTransitionsChain: [.joining, .disconnected, .error]
        )
    }

    // MARK: - Private helpers

    private func assertTransitionsWhileThrowing(
        from: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        error: Error,
        expectedTransitionsChain: [WebRTCCoordinator.StateMachine.Stage.ID],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        var transitions: [WebRTCCoordinator.StateMachine.Stage.ID] = []
        let transitionExpectation = expectation(description: "Expectation to land on id:\(expectedTarget).")
        subject.transition = {
            transitions.append($0.id)
            if $0.id == expectedTarget {
                transitionExpectation.fulfill()
            } else {
                throw error
            }
        }

        _ = subject.transition(from: .init(id: from, context: subject.context))

        await fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
        XCTAssertEqual(transitions, expectedTransitionsChain)
    }
}
