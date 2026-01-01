//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_IdleStageTests: XCTestCase, @unchecked Sendable {

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .idle(.init())

    override func tearDown() {
        allOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .idle)
    }

    // MARK: - transition

    func test_transition() {
        for nextStage in allOtherStages {
            XCTAssertNotNil(subject.transition(from: nextStage))
        }
    }
}
