//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
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
        .peerConnectionPreparing(.init(), telemetryReporter: .init())

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

    func test_transition_whenPublisherConnectionDoesNotBecomeReadyWithinTimeout_reportsTelemetryAndTransitionsToJoined(
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
        subject = .peerConnectionPreparing(context, telemetryReporter: .init())
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId

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

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(
            mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID,
            unifiedSessionId
        )

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTAssertTrue(true)
        case .reconnection:
            XCTFail()
        case .none:
            XCTFail()
        }

        completionCancellable.cancel()
    }

    func test_transition_whenSubscriberDoesNotBecomeReadyWithinTimeout_transitionsToJoinedWithoutWaitingForSubscriber(
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

        let publisherConnectionState = CurrentValueSubject<RTCPeerConnectionState, Never>(
            .connected
        )
        let subscriberConnectionState = CurrentValueSubject<
            RTCPeerConnectionState,
            Never
        >(.new)
        let publisherCoordinator = try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: .publisher,
                sfuAdapter: mockCoordinatorStack.sfuStack.adapter
            )
        )
        let subscriberCoordinator = try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: mockCoordinatorStack.sfuStack.adapter
            )
        )
        publisherCoordinator.stub(
            for: \.connectionStatePublisher,
            with: publisherConnectionState.eraseToAnyPublisher()
        )
        subscriberCoordinator.stub(
            for: \.connectionStatePublisher,
            with: subscriberConnectionState.eraseToAnyPublisher()
        )
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = publisherCoordinator
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = subscriberCoordinator

        let context = WebRTCCoordinator.StateMachine.Stage.Context(
            coordinator: mockCoordinatorStack.coordinator,
            initialJoinCallResponse: expectedJoinCallResponse,
            joinResponseHandler: completionSubject
        )
        subject = .peerConnectionPreparing(context, telemetryReporter: .init())
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId

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
            timeout: 1
        )
        XCTAssertEqual(receivedCallID, expectedJoinCallResponse.call.cid)

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(
            mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID,
            unifiedSessionId
        )

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTAssertTrue(true)
        case .reconnection:
            XCTFail()
        case .none:
            XCTFail()
        }

        completionCancellable.cancel()
    }
}
