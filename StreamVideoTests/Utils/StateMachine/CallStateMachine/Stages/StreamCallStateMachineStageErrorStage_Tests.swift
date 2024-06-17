//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class StreamCallStateMachineStageErrorStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [StreamCallStateMachine.Stage]! = StreamCallStateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { StreamCallStateMachine.Stage(id: $0, call: call) }
    private lazy var validOtherStages: Set<StreamCallStateMachine.Stage.ID>! = [
        .joining, .accepting, .rejecting
    ]
    private lazy var error: Error! = {
        TestError()
    }()

    private lazy var subject: StreamCallStateMachine.Stage! = .error(call, error: error)
    private var transitionedToStage: StreamCallStateMachine.Stage?

    override func tearDown() {
        call = nil
        allOtherStages = nil
        validOtherStages = nil
        error = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .error)
        XCTAssertTrue(subject.call === call)
        XCTAssertTrue((subject as? StreamCallStateMachine.Stage.ErrorStage)?.error is TestError)
    }

    // MARK: - Test Transition

    func testTransition() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                subject.transition = { self.transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfillment(timeout: defaultTimeout) { self.transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .idle)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }
}
