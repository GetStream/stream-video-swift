//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamCallStateMachineTests: StreamVideoTestCase {

    private lazy var mockCall: Call! = .dummy(callId: .unique)
    private lazy var subject: StreamCallStateMachine! = .init(mockCall)

    override func tearDown() {
        mockCall = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        // Then
        XCTAssertEqual(subject.currentStage.call?.callId, mockCall.callId)
        XCTAssertEqual(subject.currentStage.id, StreamCallStateMachine.Stage.ID.idle)
    }

    // MARK: - Test Transition

    func testValidTransition() {
        // Given
        let nextState = StreamCallStateMachine.Stage.AcceptingStage(mockCall, actionBlock: { .init(duration: "") })

        // When
        XCTAssertNoThrow(try subject.transition(nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(subject.currentStage.call?.callId, mockCall.callId, "Current stage call ID should match mock call ID")
        XCTAssertEqual(subject.currentStage.id, StreamCallStateMachine.Stage.ID.accepting)
    }

    func testInvalidTransition() {
        // Given
        let nextState = StreamCallStateMachine.Stage.AcceptedStage(
            mockCall,
            response: .init(duration: "")
        )

        // When
        XCTAssertThrowsError(try subject.transition(nextState), "Transition should throw")

        // Then
        XCTAssertEqual(subject.currentStage.call?.callId, mockCall.callId, "Current stage call ID should match mock call ID")
        XCTAssertEqual(subject.currentStage.id, StreamCallStateMachine.Stage.ID.idle)
    }

//    // MARK: - Test Next Stage
//
    func testNextStageShouldBe() async throws {
        // Given
        let response = AcceptCallResponse(duration: "123")

        // When
        try subject.transition(.accepting(mockCall, actionBlock: {
            try await Task.sleep(nanoseconds: 500_000_000)
            return response
        }))
        let nextStage = try await subject.nextStageShouldBe(
            StreamCallStateMachine.Stage.AcceptedStage.self,
            dropFirst: 1
        )

        // Then
        XCTAssertEqual(nextStage.call?.callId, mockCall.callId, "Received stage call ID should match mock call ID")
        XCTAssertEqual(nextStage.response, response)
    }
}
