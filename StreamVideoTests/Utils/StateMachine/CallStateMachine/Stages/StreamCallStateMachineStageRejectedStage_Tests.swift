//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamCallStateMachineStageRejectedStage_Tests: StreamVideoTestCase {

    private struct TestError: Error {}

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [StreamCallStateMachine.Stage]! = StreamCallStateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { StreamCallStateMachine.Stage(id: $0, call: call) }
    private lazy var validOtherStages: Set<StreamCallStateMachine.Stage.ID>! = [
        .rejecting
    ]
    private lazy var response: RejectCallResponse! = .init(duration: .unique)
    private lazy var subject: StreamCallStateMachine.Stage! = .rejected(call, response: response)

    override func tearDown() {
        call = nil
        allOtherStages = nil
        validOtherStages = nil
        response = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .rejected)
        XCTAssertTrue(subject.call === call)
        XCTAssertEqual((subject as? StreamCallStateMachine.Stage.RejectedStage)?.response, response)
    }

    // MARK: - Test Transition

    func testTransition() {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }
}
