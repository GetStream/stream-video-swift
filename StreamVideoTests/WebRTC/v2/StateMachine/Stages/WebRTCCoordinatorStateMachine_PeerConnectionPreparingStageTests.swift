//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_PeerConnectionPreparingStageTests:
    XCTestCase,
    @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! =
        WebRTCCoordinator
            .StateMachine
            .Stage
            .ID
            .allCases
            .filter { $0 != subject.id }
            .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! =
        [.joining]
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! =
        .peerConnectionPreparing(.init(), timeout: 0.01, telemetryReporter: .init())

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        allOtherStages = nil
        validStages = nil
        mockCoordinatorStack = nil
        subject = nil
        super.tearDown()
    }

    func test_init() {
        XCTAssertEqual(subject.id, .peerConnectionPreparing)
    }

    func test_transition() {
        for nextStage in allOtherStages {
            if validStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage))
            }
        }
    }

    func test_transition_whenPeerConnectionsDoNotBecomeReadyWithinTimeout_reportsJoinCompletionAndTransitionsToJoined(
    ) async throws {
        let expectedJoinCallResponse = JoinCallResponse.dummy(
            call: .dummy(cid: "expected-call-id")
        )
        let completionSubject = PassthroughSubject<JoinCallResponse, Error>()
        let completionExpectation = expectation(
            description: "JoinResponseHandler should receive response."
        )
        var receivedCallID: String?
        let completionCancellable = completionSubject.sink(
            receiveCompletion: { _ in },
            receiveValue: { response in
                receivedCallID = response.call.cid
                completionExpectation.fulfill()
            }
        )

        let context = WebRTCCoordinator.StateMachine.Stage.Context(
            coordinator: mockCoordinatorStack.coordinator,
            initialJoinCallResponse: expectedJoinCallResponse,
            joinResponseHandler: completionSubject
        )
        subject = .peerConnectionPreparing(context, timeout: 0.01, telemetryReporter: .init())

        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()

        let transitionExpectation = expectation(
            description: "Stage is expected to transition to joined."
        )
        subject.transition = { target in
            guard target.id == .joined else { return }
            XCTAssertNil(target.context.initialJoinCallResponse)
            XCTAssertNil(target.context.joinResponseHandler)
            transitionExpectation.fulfill()
        }

        _ = subject.transition(from: .joining(subject.context))

        await fulfillment(
            of: [transitionExpectation, completionExpectation],
            timeout: defaultTimeout
        )
        XCTAssertEqual(receivedCallID, expectedJoinCallResponse.call.cid)

        completionCancellable.cancel()
    }
}
