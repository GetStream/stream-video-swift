//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinator_StateMachineTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: WebRTCCoordinator.StateMachine! = .init(.init())

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.currentStage.id, .idle)
    }

    // MARK: - Test Transition

    func testValidTransition() {
        // Given
        let nextState = WebRTCCoordinator.StateMachine.Stage.connecting(
            .init(),
            create: false,
            options: nil,
            ring: false,
            notify: false
        )
        XCTAssertEqual(subject.currentStage.id, .idle)

        // When
        XCTAssertNoThrow(subject.transition(nextState), "Transition should not throw")

        // Then
        XCTAssertEqual(subject.currentStage.id, .connecting)
    }

    func testInvalidTransition() throws {
        // Given
        let nextState = WebRTCCoordinator.StateMachine.Stage.migrated(.init())
        XCTAssertEqual(subject.currentStage.id, .idle)

        // When
        XCTAssertNoThrow(subject.transition(nextState), "Transition should throw")

        // Then
        XCTAssertEqual(subject.currentStage.id, .idle)
    }
}
