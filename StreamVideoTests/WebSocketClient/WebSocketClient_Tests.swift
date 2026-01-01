//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebSocketClient_Tests: XCTestCase, @unchecked Sendable {
    // The longest time WebSocket waits to reconnect.
    let maxReconnectTimeout: VirtualTime.Seconds = 25

    var webSocketClient: WebSocketClient!

    var time: VirtualTime!
    private var decoder: EventDecoder_Mock!
    var engine: WebSocketEngine_Mock? { webSocketClient.engine as? WebSocketEngine_Mock }
    var connectionId: String!
    var user: User!
    var pingController: WebSocketPingController_Mock { webSocketClient.pingController as! WebSocketPingController_Mock }
    var eventsBatcher: EventBatcher_Mock { webSocketClient.eventsBatcher as! EventBatcher_Mock }

    var eventNotificationCenter: EventNotificationCenter_Mock!
    private var eventNotificationCenterMiddleware: EventMiddleware_Mock!
    
    private let connectURL = URL(string: "http://example.com/ws")!
    
    private let createdAt = Date()
    private lazy var healthCheckInfo = HealthCheckInfo(
        coordinatorHealthCheck: HealthCheckEvent(
            connectionId: connectionId,
            createdAt: createdAt
        )
    )
    
    override func setUp() {
        super.setUp()

        time = VirtualTime()
        VirtualTimeTimer.time = time

        decoder = EventDecoder_Mock()

        eventNotificationCenter = EventNotificationCenter_Mock()
        eventNotificationCenterMiddleware = EventMiddleware_Mock()
        eventNotificationCenter.add(middleware: eventNotificationCenterMiddleware)

        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self

        webSocketClient = WebSocketClient(
            sessionConfiguration: .ephemeral,
            eventDecoder: decoder,
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .coordinator,
            environment: environment,
            connectURL: connectURL
        )

        connectionId = UUID().uuidString
        user = User(id: "test_user_\(UUID().uuidString)")
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&webSocketClient)
        AssertAsync.canBeReleased(&eventNotificationCenter)
        AssertAsync.canBeReleased(&eventNotificationCenterMiddleware)

        webSocketClient = nil
        eventNotificationCenter = nil
        eventNotificationCenterMiddleware = nil
        VirtualTimeTimer.invalidate()
        time = nil
        decoder = nil
        connectionId = nil
        user = nil

        super.tearDown()
    }

    // MARK: - Setup

    func test_webSocketClient_isInstantiatedInCorrectState() {
        XCTAssertNil(webSocketClient.engine)
    }

    func test_engine_isReused_ifRequestIsNotChanged() {
        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()
        // Save currently existed engine.
        let oldEngine = webSocketClient.engine
        // Disconnect the client.
        webSocketClient.disconnect {}

        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()

        // Assert engine is reused since the connect request is not changed.
        XCTAssertTrue(oldEngine === webSocketClient.engine)
    }

    // MARK: - Connection tests

    func test_connectionFlow() {
        assert(webSocketClient.connectionState == .initialized)

        webSocketClient.connect()
        XCTAssertEqual(webSocketClient.connectionState, .connecting)

        AssertAsync {
            Assert.willBeEqual(self.engine!.connect_calledCount, 1)
        }

        // Simulate the engine is connected and check the connection state is updated
        engine!.simulateConnectionSuccess()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .authenticating)

        // Simulate a health check event is received and the connection state is updated
        decoder
            .decodedEvent =
            .success(.coordinatorEvent(.typeHealthCheckEvent(HealthCheckEvent(connectionId: connectionId, createdAt: createdAt))))
        engine!.simulateMessageReceived()

        AssertAsync.willBeEqual(webSocketClient.connectionState, .connected(healthCheckInfo: healthCheckInfo))
    }

    func test_callingConnect_whenAlreadyConnected_hasNoEffect() {
        // Simulate connection
        test_connectionFlow()

        assert(webSocketClient.connectionState == .connected(healthCheckInfo: healthCheckInfo))
        assert(engine!.connect_calledCount == 1)

        // Call connect and assert it has no effect
        webSocketClient.connect()
        AssertAsync {
            Assert.staysTrue(self.engine!.connect_calledCount == 1)
            Assert.staysTrue(self.webSocketClient.connectionState == .connected(healthCheckInfo: self.healthCheckInfo))
        }
    }

    func test_disconnect_callsEngine() {
        // Simulate connection
        test_connectionFlow()

        assert(webSocketClient.connectionState == .connected(healthCheckInfo: healthCheckInfo))
        assert(engine!.disconnect_calledCount == 0)

        // Call `disconnect`, it should change connection state and call `disconnect` on the engine
        let source: WebSocketConnectionState.DisconnectionSource = .userInitiated
        webSocketClient.disconnect(source: source) {}

        // Assert disconnect is called
        AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
    }

    func test_whenConnectedAndEngineDisconnectsWithServerError_itIsTreatedAsServerInitiatedDisconnect() {
        // Simulate connection
        test_connectionFlow()

        // Simulate the engine disconnecting with server error
        let errorPayload = ErrorPayload(
            code: .unique,
            message: .unique,
            statusCode: .unique
        )
        let engineError = WebSocketEngineError(
            reason: UUID().uuidString,
            code: 0,
            engineError: errorPayload
        )
        engine!.simulateDisconnect(engineError)

        // Assert state is disconnected with `systemInitiated` source
        XCTAssertEqual(
            webSocketClient.connectionState,
            .disconnected(source: .serverInitiated(error: ClientError.WebSocket(with: engineError)))
        )
    }

    func test_disconnect_propagatesDisconnectionSource() {
        // Simulate connection
        test_connectionFlow()

        let testCases: [WebSocketConnectionState.DisconnectionSource] = [
            .userInitiated,
            .systemInitiated,
            .serverInitiated(error: nil),
            .serverInitiated(error: .init(.unique))
        ]

        for source in testCases {
            engine?.disconnect_calledCount = 0

            // Call `disconnect` with the given source
            webSocketClient.disconnect(source: source) {}

            // Assert connection state is changed to disconnecting respecting the source
            XCTAssertEqual(webSocketClient.connectionState, .disconnecting(source: source))

            // Assert disconnect is called
            AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)

            // Simulate engine disconnection
            engine!.simulateDisconnect()

            // Assert state is `disconnected` with the correct source
            AssertAsync.willBeEqual(webSocketClient.connectionState, .disconnected(source: source))
        }
    }

    func test_connectionState_afterDecodingError() {
        // Simulate connection
        test_connectionFlow()

        decoder.decodedEvent = .failure(
            ClientError.UnsupportedEventType()
        )
        engine!.simulateMessageReceived()

        AssertAsync.staysEqual(webSocketClient.connectionState, .connected(healthCheckInfo: healthCheckInfo))
    }

    // MARK: - Ping Controller

    func test_webSocketPingController_connectionStateDidChange_calledWhenConnectionChanges() {
        test_connectionFlow()
        AssertAsync.willBeEqual(
            pingController.connectionStateDidChange_connectionStates,
            [
                .connecting,
                .authenticating,
                .connected(healthCheckInfo: healthCheckInfo),
                .connected(healthCheckInfo: healthCheckInfo)
            ]
        )
    }

    func test_webSocketPingController_ping_callsEngineWithPing() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        // Reset the counter
        engine!.sendPing_calledCount = 0

        pingController.delegate?.sendPing()
        AssertAsync.willBeEqual(engine!.sendPing_calledCount, 1)
    }

    func test_pongReceived_callsPingController_pongReceived() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        assert(pingController.pongReceivedCount == 1)

        // Simulate a health check (pong) event is received
        decoder.decodedEvent = .success(
            .coordinatorEvent(
                .typeHealthCheckEvent(
                    HealthCheckEvent(connectionId: connectionId, createdAt: createdAt)
                )
            )
        )
        engine!.simulateMessageReceived()

        AssertAsync.willBeEqual(pingController.pongReceivedCount, 2)
    }

    func test_webSocketPingController_disconnectOnNoPongReceived_disconnectsEngine() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()

        assert(engine!.disconnect_calledCount == 0)

        pingController.delegate?.disconnectOnNoPongReceived()

        AssertAsync {
            Assert.willBeEqual(self.webSocketClient.connectionState, .disconnecting(source: .noPongReceived))
            Assert.willBeEqual(self.engine!.disconnect_calledCount, 1)
        }
    }

    // MARK: - Event handling tests

    func test_whenCoordinatorHealthCheckEventComes_itGetProcessedSilentlyWithoutBatching() throws {
        // Connect the web-socket client
        webSocketClient.connect()

        // Wait for engine to be called
        AssertAsync.willBeEqual(engine!.connect_calledCount, 1)

        // Simulate engine established connection
        engine!.simulateConnectionSuccess()

        // Wait for the connection state to be propagated to web-socket client
        AssertAsync.willBeEqual(webSocketClient.connectionState, .authenticating)

        // Simulate received health check event
        let healthCheckEvent = HealthCheckEvent(connectionId: .unique, createdAt: createdAt)
        decoder.decodedEvent = .success(.coordinatorEvent(.typeHealthCheckEvent(healthCheckEvent)))
        engine!.simulateMessageReceived()

        // Assert healtch check event does not get batched
        let batchedEvents = eventsBatcher.mock_append.calls.map(\.asEquatable)
        XCTAssertFalse(batchedEvents.contains(healthCheckEvent.asEquatable))

        // Assert health check event was processed
        let (_, postNotification, _) = try XCTUnwrap(
            eventNotificationCenter.mock_process.calls.first(where: { events, _, _ in
                events.first?.healthcheck() != nil
            })
        )

        // Assert health check events was not posted
        XCTAssertFalse(postNotification)
    }

    func test_whenSFUHealthCheckEventComes_itGetProcessedSilentlyWithoutBatching() {
        let receiptExpectation = expectation(description: "HealthCheck event received")
        let cancellable = webSocketClient
            .eventSubject
            .filter { $0.name.contains("healthCheck") }
            .sink { _ in receiptExpectation.fulfill() }

        // Connect the web-socket client
        webSocketClient.connect()

        // Wait for engine to be called
        AssertAsync.willBeEqual(engine!.connect_calledCount, 1)

        // Simulate engine established connection
        engine!.simulateConnectionSuccess()

        // Wait for the connection state to be propagated to web-socket client
        AssertAsync.willBeEqual(webSocketClient.connectionState, .authenticating)

        // Simulate received health check event
        decoder.decodedEvent = .success(.sfuEvent(.healthCheckResponse(.init())))
        engine!.simulateMessageReceived()

        wait(for: [receiptExpectation], timeout: defaultTimeout)
        cancellable.cancel()
    }

    func test_whenNonHealthCheckEventComes_getsBatchedAndPostedAfterProcessing() throws {
        // Simulate connection
        test_connectionFlow()

        // Clear state
        eventsBatcher.mock_append.calls.removeAll()
        eventNotificationCenter.mock_process.calls.removeAll()

        // Simulate incoming event
        let incomingEvent = CustomVideoEvent(
            callCid: "default:123",
            createdAt: Date(),
            custom: [:],
            user: UserResponse(
                blockedUserIds: [],
                createdAt: Date(),
                custom: [:],
                id: "test",
                language: "en",
                role: "user",
                teams: [],
                updatedAt: Date()
            )
        )
        decoder.decodedEvent = .success(.coordinatorEvent(.typeCustomVideoEvent(incomingEvent)))
        engine!.simulateMessageReceived()

        // Assert event gets batched
        XCTAssertEqual(
            eventsBatcher.mock_append.calls.map(\.asEquatable),
            [WrappedEvent.coordinatorEvent(.typeCustomVideoEvent(incomingEvent)).asEquatable]
        )

        // Assert incoming event get processed and posted
        let (events, postNotifications, completion) = try XCTUnwrap(eventNotificationCenter.mock_process.calls.first)
        XCTAssertEqual(events.map(\.asEquatable), [WrappedEvent.coordinatorEvent(.typeCustomVideoEvent(incomingEvent)).asEquatable])
        XCTAssertTrue(postNotifications)
        XCTAssertNotNil(completion)
    }

    func test_whenDisconnectHappens_immidiateBatchedEventsProcessingIsTriggered() {
        // Simulate connection
        test_connectionFlow()

        // Assert `processImmediately` was not triggered
        XCTAssertFalse(eventsBatcher.mock_processImmediately.called)

        // Simulate disconnection
        let expectation = expectation(description: "disconnect completion")
        webSocketClient.disconnect {
            expectation.fulfill()
        }

        // Assert `processImmediately` is triggered
        AssertAsync.willBeTrue(eventsBatcher.mock_processImmediately.called)

        // Simulate batch processing completion
        eventsBatcher.mock_processImmediately.calls.last?()

        // Assert completion called
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
