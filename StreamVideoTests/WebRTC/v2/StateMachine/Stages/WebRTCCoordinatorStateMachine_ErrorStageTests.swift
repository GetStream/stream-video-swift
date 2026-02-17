//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_ErrorStageTests: XCTestCase, @unchecked Sendable {

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .error(
        .init(),
        error: ClientError()
    )

    override func tearDown() {
        allOtherStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .error)
    }

    // MARK: - transition

    func test_transition() {
        for nextStage in allOtherStages {
            XCTAssertNotNil(subject.transition(from: nextStage))
        }
    }

    func test_transition_landsOnCleanUp() async {
        let transitionExpectation = expectation(description: "Will transition to id:.cleanUp")
        subject.transition = {
            if $0.id == .cleanUp {
                transitionExpectation.fulfill()
            }
        }
        _ = subject.transition(from: .joining(subject.context))

        await fulfillment(of: [transitionExpectation])
    }

    func test_transition_sendsErrorToJoinResponseHandler() async {
        let handler = PassthroughSubject<JoinCallResponse, Error>()
        let expectation = expectation(description: "Join response handler receives failure")
        let expectedError = ClientError("Join failed")
        var receivedError: Error?
        let cancellable = handler.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    receivedError = error
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("No value expected before failure")
            }
        )
        subject = .error(.init(), error: expectedError)
        subject.context.joinResponseHandler = handler

        let transitionExpectation = self.expectation(description: "Will transition to id:.cleanUp")
        subject.transition = {
            if $0.id == .cleanUp {
                transitionExpectation.fulfill()
            }
        }
        _ = subject.transition(from: .joining(subject.context))

        await fulfillment(of: [transitionExpectation, expectation])
        XCTAssertTrue(receivedError is ClientError)
        cancellable.cancel()
    }
}
