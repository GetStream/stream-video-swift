//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class StreamCallStateMachineStageErrorStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var call: Call! = .dummy()
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var error: Error! = {
        TestError()
    }()

    private lazy var subject: Call.StateMachine.Stage! = .error(.init(call: call), error: error)
    private var transitionedToStage: Call.StateMachine.Stage?

    override func tearDown() {
        call = nil
        allOtherStages = nil
        error = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .error)
        XCTAssertTrue(subject.context.call === call)
        XCTAssertTrue((subject as? Call.StateMachine.Stage.ErrorStage)?.error is TestError)
    }

    // MARK: - Test Transition

    func testTransition() async {
        for nextStage in allOtherStages {
            subject.transition = { self.transitionedToStage = $0 }
            XCTAssertNotNil(subject.transition(from: nextStage))
            await fulfillment(timeout: defaultTimeout) { self.transitionedToStage != nil }
            XCTAssertEqual(transitionedToStage?.id, .idle)
        }
    }
}
