//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamCallStateMachineStageAcceptingStage_Tests: StreamVideoTestCase {

    private struct TestError: Error {}

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [StreamCallStateMachine.Stage]! = StreamCallStateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { StreamCallStateMachine.Stage(id: $0, call: call) }
    private lazy var validOtherStages: Set<StreamCallStateMachine.Stage.ID>! = [
        .idle
    ]
    private lazy var subject: StreamCallStateMachine.Stage! = .accepting(call) { .init(duration: "123") }

    override func tearDown() {
        call = nil
        allOtherStages = nil
        validOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .accepting)
        XCTAssertTrue(subject.call === call)
    }

    // MARK: - Test Transition

    func testTransition() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                var transitionedToStage: StreamCallStateMachine.Stage?
                subject.transition = { transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfillment(timeout: defaultTimeout) { transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .accepted)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }

    func testTransitionAfterError() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                var transitionedToStage: StreamCallStateMachine.Stage?
                subject = .accepting(call) { throw TestError() }
                subject.transition = { transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfillment(timeout: defaultTimeout) { transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .error)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }
}
