//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallStateMachineTests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var mockCall: Call! = .dummy(callId: .unique)
    private lazy var subject: Call.StateMachine! = .init(mockCall)

    override func tearDown() {
        mockCall = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        // Then
        XCTAssertEqual(subject.currentStage.context.call?.callId, mockCall.callId)
        XCTAssertEqual(subject.currentStage.id, Call.StateMachine.Stage.ID.idle)
    }

    // MARK: - Test Transition

    func testValidTransition() {
        // Given
        let nextState = Call.StateMachine.Stage.AcceptingStage(.init(call: mockCall))
        XCTAssertEqual(subject.currentStage.id, .idle)

        // When
        XCTAssertNoThrow(subject.transition(nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(
            subject.currentStage.context.call?.callId,
            mockCall.callId,
            "Current stage call ID should match mock call ID"
        )
        XCTAssertEqual(subject.currentStage.id, Call.StateMachine.Stage.ID.accepting)
    }

    func testInvalidTransition() {
        // Given
        let nextState = Call.StateMachine.Stage.AcceptedStage(
            .init(call: mockCall)
        )

        // When
        XCTAssertNoThrow(subject.transition(nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(
            subject.currentStage.context.call?.callId,
            mockCall.callId,
            "Current stage call ID should match mock call ID"
        )
        XCTAssertEqual(subject.currentStage.id, Call.StateMachine.Stage.ID.idle)
    }
}
