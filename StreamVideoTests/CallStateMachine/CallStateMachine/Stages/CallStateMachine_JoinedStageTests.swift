//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class CallStateMachineStageJoinedStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .joining
    ]
    private lazy var response: JoinCallResponse! = .dummy()
    private lazy var subject: Call.StateMachine.Stage! = .joined(.init(call: call), response: response)

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
        XCTAssertEqual(subject.id, .joined)
        XCTAssertTrue(subject.context.call === call)
        XCTAssertEqual(subject.context.output.joinResponse, response)
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

extension Call.StateMachine.Stage.Context.Output {
    var joinResponse: JoinCallResponse? {
        switch self {
        case let .joined(output):
            return output
        default:
            return nil
        }
    }
}
