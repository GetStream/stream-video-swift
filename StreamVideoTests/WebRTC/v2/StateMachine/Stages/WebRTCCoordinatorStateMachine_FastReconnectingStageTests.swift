//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_FastReconnectingStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.disconnected]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .fastReconnecting(.init())
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        allOtherStages = nil
        validStages = nil
        subject = nil
        mockCoordinatorStack = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .fastReconnecting)
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

    func test_transition_withoutCoordinator_transitionsToDisconnected() async {
        await assertTransitions(
            from: .disconnected,
            expectedTarget: .disconnected,
            expectedTransitionsChain: [.disconnected]
        )
    }

    func test_transition_withCoordinatorAndDisconnectedFails_transitionsToError() async {
        await assertTransitions(
            from: .disconnected,
            expectedTarget: .error,
            transitionError: ClientError(),
            expectedTransitionsChain: [.disconnected, .error]
        )
    }

    func test_transition_withoutSFUAdapter_transitionsToDisconnected() async {
        subject.context.coordinator = mockCoordinatorStack.coordinator

        await assertTransitions(
            from: .disconnected,
            expectedTarget: .disconnected,
            expectedTransitionsChain: [.disconnected]
        )
    }

    func test_transition_withSFUADapterAndDisconnectedFails_transitionsToError() async {
        subject.context.coordinator = mockCoordinatorStack.coordinator

        await assertTransitions(
            from: .disconnected,
            expectedTarget: .error,
            transitionError: ClientError(),
            expectedTransitionsChain: [.disconnected, .error]
        )
    }

    func test_transition_refreshWasCalledOnSFUAdapter_oldWebSocketClientWasClosedCorrectly() async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let webSocket = mockCoordinatorStack.sfuStack.webSocket
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        let callType = (
            code: URLSessionWebSocketTask.CloseCode,
            source: WebSocketConnectionState.DisconnectionSource,
            completion: () -> Void
        ).self
        XCTAssertNil(webSocket.connectionStateDelegate)
        XCTAssertEqual(webSocket.timesCalled(.disconnect), 1)
        XCTAssertEqual(
            webSocket.recordedInputPayload(
                callType,
                for: .disconnect
            )?.first?.code,
            .init(rawValue: 4002)
        )
    }

    func test_transition_refreshWasCalledOnSFUAdapter_newWebSocketClientWasConfiguredCorrectly() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
        let newWebSocket = MockWebSocketClient(webSocketClientType: .sfu)
        mockCoordinatorStack.sfuStack.webSocketFactory.stub(
            for: .build,
            with: newWebSocket
        )

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        let buildCallType = (
            sessionConfiguration: URLSessionConfiguration,
            eventDecoder: AnyEventDecoder,
            eventNotificationCenter: EventNotificationCenter,
            webSocketClientType: WebSocketClientType,
            environment: WebSocketClient.Environment,
            connectURL: URL,
            requiresAuth: Bool
        ).self
        let newWebSocketBuildInput = try XCTUnwrap(
            mockCoordinatorStack
                .sfuStack
                .webSocketFactory
                .recordedInputPayload(buildCallType, for: .build)?
                .first
        )
        XCTAssertEqual(newWebSocketBuildInput.webSocketClientType, .sfu)
        XCTAssertEqual(newWebSocketBuildInput.connectURL, sfuAdapter.connectURL)
        XCTAssertFalse(newWebSocketBuildInput.requiresAuth)
        XCTAssertTrue(newWebSocket.connectionStateDelegate === sfuAdapter)
    }

    func test_transition_connectWasCalledOnSFUAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
        let newWebSocket = MockWebSocketClient(webSocketClientType: .sfu)
        mockCoordinatorStack.sfuStack.webSocketFactory.stub(
            for: .build,
            with: newWebSocket
        )

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        XCTAssertEqual(newWebSocket.timesCalled(.connect), 1)
    }

    func test_transition_SFUStateChangesToAuthenticating_transitionsToFastReconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 12)
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
        let newWebSocket = MockWebSocketClient(webSocketClientType: .sfu)
        mockCoordinatorStack.sfuStack.webSocketFactory.stub(
            for: .build,
            with: newWebSocket
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .fastReconnected
        ) {
            newWebSocket.simulate(state: .authenticating)
        } validationHandler: { _ in }
    }

    func test_transition_SFUStateChangesToOther_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 12)
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
        let newWebSocket = MockWebSocketClient(webSocketClientType: .sfu)
        mockCoordinatorStack.sfuStack.webSocketFactory.stub(
            for: .build,
            with: newWebSocket
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected
        ) {
            newWebSocket.simulate(state: .disconnected(source: .noPongReceived))
        } validationHandler: { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .rejoin)
        }
    }

    // MARK: - Private helpers

    private func assertTransitions(
        from: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        transitionError: Error? = nil,
        expectedTransitionsChain: [WebRTCCoordinator.StateMachine.Stage.ID],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        var transitions: [WebRTCCoordinator.StateMachine.Stage.ID] = []
        let transitionExpectation = expectation(description: "Expectation to land on id:\(expectedTarget).")
        subject.transition = {
            transitions.append($0.id)
            if $0.id == expectedTarget {
                transitionExpectation.fulfill()
            } else if let transitionError {
                throw transitionError
            }
        }

        _ = subject.transition(from: .init(id: from, context: subject.context))

        await fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
        XCTAssertEqual(transitions, expectedTransitionsChain)
    }

    private func assertResultAfterTrigger(
        trigger: @escaping @Sendable () async -> Void,
        validationHandler: @escaping @Sendable (XCTestExpectation) async -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)
        let resultExpectation = expectation(description: "Expectation to for desired result to occur.")

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.wait(for: 0.2)
                await trigger()
                await self.wait(for: 0.3)
                await validationHandler(resultExpectation)
            }

            group.addTask {
                await self.fulfillment(of: [resultExpectation], timeout: defaultTimeout)
            }

            await group.waitForAll()
        }
    }

    private func assertTransitionAfterTrigger(
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID? = nil,
        trigger: @escaping @Sendable () async -> Void,
        validationHandler: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = subject.transition(from: .disconnected(subject.context))

        let transitionExpectation: XCTestExpectation

        if let expectedTarget {
            transitionExpectation = expectation(
                description: "Expectation to land on id:\(expectedTarget)."
            )
        } else {
            transitionExpectation = expectation(
                description: "Expectation to remain in the id without transitions."
            )
            transitionExpectation.isInverted = true
        }

        subject.transition = { target in
            Task {
                if target.id == expectedTarget {
                    await validationHandler(target)
                    transitionExpectation.fulfill()
                } else if let expectedTarget {
                    transitionExpectation
                        .expectationDescription =
                        "Expectation to land on id:\(expectedTarget) but instead landed on id:\(target.id)."
                }
            }
        }

        await withTaskGroup(of: Void.self) { [subject] group in
            group.addTask {
                await self.wait(for: 0.3)
                await trigger()
            }

            group.addTask {
                await self.fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
                if transitionExpectation.isInverted {
                    await validationHandler(subject!)
                }
            }

            await group.waitForAll()
        }
    }
}
