//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamCallStateMachineStageIdleStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var subject: Call.StateMachine.Stage! = .idle(.init(call: call))

    override func tearDown() {
        call = nil
        allOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .idle)
        XCTAssertTrue(subject.context.call === call)
    }

    // MARK: - Test Transition

    func testTransition() {
        for nextStage in allOtherStages {
            XCTAssertNoThrow(subject.transition(from: nextStage))
        }
    }
}
