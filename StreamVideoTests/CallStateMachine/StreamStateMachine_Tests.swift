//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class StreamStateMachineTests: XCTestCase, @unchecked Sendable {

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
        XCTAssertNoThrow(stateMachine.transition(to: nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(stateMachine.currentStage.id, nextState.id, "Current state should match next state")
    }

    func testTransitionThrowsError() {
        // Given
        let initialState = MockStage(id: "Initial", description: "Initial State")
        let nextState = MockStage(id: "Next", description: "Next State", allowedTransitions: [])
        let stateMachine = StreamStateMachine(initialStage: initialState)

        // When
        XCTAssertNoThrow(stateMachine.transition(to: nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(stateMachine.currentStage.id, initialState.id)
    }

    func test_transition_rejected_keepsActiveStageLifecycle() throws {
        let initialStage = MockStage(id: "Initial", description: "Initial")
        let activeStage = MockStage(
            id: "Active", description: "Active", allowedTransitions: [initialStage]
        )
        let subject = StreamStateMachine(initialStage: initialStage)
        subject.transition(to: activeStage)

        subject.transition(to: MockStage(id: "Rejected", description: "Rejected"))

        XCTAssertTrue(subject.currentStage === activeStage)
        XCTAssertFalse(activeStage.willTransitionAwayWasCalled)
        XCTAssertFalse(activeStage.didTransitionAwayWasCalled)
        let recoveryStage = MockStage(
            id: "Recovery", description: "Recovery", allowedTransitions: [activeStage]
        )
        try activeStage.transition?(recoveryStage)
        XCTAssertTrue(subject.currentStage === recoveryStage)
        XCTAssertTrue(activeStage.willTransitionAwayWasCalled)
        XCTAssertTrue(activeStage.didTransitionAwayWasCalled)
    }

    func test_transition_oldCallbackWithSameStageID_keepsReplacementActive() throws {
        let initialStage = MockStage(id: "Initial", description: "Initial")
        let oldStage = MockStage(
            id: "Joined", description: "Old joined", allowedTransitions: [initialStage]
        )
        let subject = StreamStateMachine(initialStage: initialStage)
        subject.transition(to: oldStage)
        let callback = try XCTUnwrap(oldStage.transition)
        let replacement = MockStage(
            id: "Joined", description: "New joined", allowedTransitions: [oldStage]
        )
        subject.transition(to: replacement)

        try callback(MockStage(
            id: "Disconnected", description: "Disconnected", allowedTransitions: [replacement]
        ))

        XCTAssertTrue(subject.currentStage === replacement)
        XCTAssertFalse(replacement.willTransitionAwayWasCalled)
    }

    func test_transition_rejectedStageCallback_cannotAdvanceActiveStage() throws {
        let activeStage = MockStage(id: "Active", description: "Active")
        let subject = StreamStateMachine(initialStage: activeStage)
        let rejectedStage = MockStage(id: "Rejected", description: "Rejected")
        subject.transition(to: rejectedStage)

        try rejectedStage.transition?(MockStage(
            id: "Recovery", description: "Recovery", allowedTransitions: [activeStage]
        ))

        XCTAssertTrue(subject.currentStage === activeStage)
    }

    // MARK: - Mocks

    private final class MockStage: StreamStateMachineStage {
        var id: String
        var container: String
        var description: String
        var allowedTransitions: [MockStage]

        private(set) var willTransitionAwayWasCalled = false
        var transition: ((MockStage) throws -> Void)?
        private(set) var didTransitionAwayWasCalled = false

        init(
            id: String,
            container: String = .unique,
            description: String,
            allowedTransitions: [MockStage] = []
        ) {
            self.id = id
            self.container = container
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
