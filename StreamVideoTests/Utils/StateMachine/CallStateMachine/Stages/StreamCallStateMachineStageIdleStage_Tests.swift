//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamCallStateMachineStageIdleStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [StreamCallStateMachine.Stage]! = StreamCallStateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { StreamCallStateMachine.Stage(id: $0, call: call) }
    private lazy var subject: StreamCallStateMachine.Stage! = .idle(call)

    override func tearDown() {
        call = nil
        allOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .idle)
        XCTAssertTrue(subject.call === call)
    }

    // MARK: - Test Transition

    func testTransition() {
        for nextStage in allOtherStages {
            XCTAssertNoThrow(subject.transition(from: nextStage))
        }
    }
}
