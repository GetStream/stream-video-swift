//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_HLSPlaybackStageTests: XCTestCase, @unchecked Sendable {

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.connecting]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .hlsPlayback(.init())

    // MARK: - Lifecycle

    override func tearDown() {
        allOtherStages = nil
        validStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .hlsPlayback)
    }

    // MARK: - transition

    func test_transition() {
        for nextStage in allOtherStages {
            if validStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage))
            }
        }
    }

    func test_transition_fromConnecting_reportsJoinCompletion() async throws {
        let expected = JoinCallResponse.dummyHLSGrant()
        let joinResponseHandler = PassthroughSubject<JoinCallResponse, Error>()
        let relay = joinResponseHandler.relay()
        subject.context.initialJoinCallResponse = expected
        subject.context.joinResponseHandler = joinResponseHandler

        _ = subject.transition(from: .init(id: .connecting, context: subject.context))

        let response = try await relay.nextValue(timeout: defaultTimeout)
        XCTAssertEqual(response, expected)
    }

    func test_transition_fromConnecting_reportsTheJoinBeforeTheStageCanBeLeft() {
        subject.context.initialJoinCallResponse = .dummyHLSGrant()
        subject.context.joinResponseHandler = .init()

        _ = subject.transition(from: .init(id: .connecting, context: subject.context))

        XCTAssertNil(subject.context.initialJoinCallResponse)
        XCTAssertNil(subject.context.joinResponseHandler)
    }
}
