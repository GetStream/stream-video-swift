//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class StreamStateMachineTests: XCTestCase {

    // MARK: - Test Initial State

    func testInitialState() {
        // Given
        let initialState = MockStage(id: "Initial", description: "Initial State")
        let stateMachine = StreamStateMachine(initialStage: initialState)

        // When
        let currentState = stateMachine.currentStage

        // Then
        XCTAssertEqual(currentState.id, initialState.id, "Current state should match initial state")
    }

    // MARK: - Test Transition

    func testTransition() {
        // Given
        let initialState = MockStage(id: "Initial", description: "Initial State")
        let nextState = MockStage(
            id: "Next",
            description: "Next State",
            allowedTransitions: [initialState]
        )
        let stateMachine = StreamStateMachine(initialStage: initialState)

        // When
        XCTAssertNoThrow(try stateMachine.transition(to: nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(stateMachine.currentStage.id, nextState.id, "Current state should match next state")
    }

    func testTransitionThrowsError() {
        // Given
        let initialState = MockStage(id: "Initial", description: "Initial State")
        let nextState = MockStage(id: "Next", description: "Next State", allowedTransitions: [])
        let stateMachine = StreamStateMachine(initialStage: initialState)

        // When, Then
        XCTAssertThrowsError(try stateMachine.transition(to: nextState), "Transition should throw") { error in
            XCTAssertTrue(error is ClientError.InvalidStateMachineTransition, "Error should be of type ClientError")
        }
    }

    // MARK: - Mocks

    private final class MockStage: StreamStateMachineStage {

        var id: String
        var description: String
        var allowedTransitions: [MockStage]

        private(set) var willTransitionAwayWasCalled = false
        var transition: ((MockStage) throws -> Void)?
        private(set) var didTransitionAwayWasCalled = false

        init(id: String, description: String, allowedTransitions: [MockStage] = []) {
            self.id = id
            self.description = description
            self.allowedTransitions = allowedTransitions
        }

        func willTransitionAway() {
            willTransitionAwayWasCalled = true
        }

        func transition(from currentStage: MockStage) -> Self? {
            if allowedTransitions.contains(where: { $0.id == currentStage.id }) {
                return self
            }
            return nil
        }

        func didTransitionAway() {
            didTransitionAwayWasCalled = true
        }
    }
}
