//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SFUAdapterTests: XCTestCase, @unchecked Sendable {
    private lazy var mockService: MockSignalServer! = .init()
    private lazy var mockWebSocket: MockWebSocketClient! = .init(webSocketClientType: .sfu)
    private lazy var subject: SFUAdapter! = .init(
        signalService: mockService,
        webSocket: mockWebSocket,
        webSocketFactory: MockWebSocketClientFactory()
    )

    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        subject = nil
        mockService = nil
        mockWebSocket = nil
        super.tearDown()
    }

    // MARK: - connect

    func test_init_webSocketDelegateWasSetCorrectly() {
        _ = subject

        XCTAssertTrue(mockWebSocket.connectionStateDelegate === subject)
    }

    // MARK: - connect

    func test_connect_givenValidConfiguration_thenCallsWebSocketConnect() {
        // When
        subject.connect()

        // Then
        XCTAssertEqual(mockWebSocket.timesCalled(.connect), 1)
    }

    // MARK: - disconnect

    func test_disconnect_givenConnectedState_thenCallsWebSocketDisconnect() async {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))

        // When
        await subject.disconnect()

        // Then
        XCTAssertEqual(mockWebSocket.timesCalled(.disconnectAsync), 1)
    }

    // MARK: - sendHealthCheck

    func test_sendHealthCheck_givenConnectedState_thenSendsHealthCheckRequest() throws {
        // When
        subject.sendHealthCheck()

        // Then
        let input = try XCTUnwrap(
            mockWebSocket.mockEngine.recordedInputPayload(
                Stream_Video_Sfu_Event_HealthCheckRequest.self,
                for: .sendMessage
            )
        )

        XCTAssertNotNil(input.first)
    }

    // MARK: - sendMessage

    func test_sendMessage_webSocketEngineWasCalled() throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))

        // When
        subject.send(message: Stream_Video_Sfu_Event_HealthCheckRequest())

        // Then
        let input = try XCTUnwrap(
            mockWebSocket.mockEngine.recordedInputPayload(
                Stream_Video_Sfu_Event_HealthCheckRequest.self,
                for: .sendMessage
            )
        )

        XCTAssertNotNil(input.first)
    }

    // MARK: - refresh
    
    func test_refresh_currentWebSocketDisconnects() {
        subject.refresh(
            webSocketConfiguration: .init(
                url: .init(string: "https://getstream.io")!,
                eventNotificationCenter: .init()
            )
        )

        XCTAssertEqual(mockWebSocket.timesCalled(.disconnect), 1)
    }

    func test_refresh_oldWebSocketDisconnectsNoLongerReceivesCalls() throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))

        subject.refresh(
            webSocketConfiguration: .init(
                url: .init(string: "https://getstream.io")!,
                eventNotificationCenter: .init()
            )
        )

        subject.sendHealthCheck()

        let input = try XCTUnwrap(
            mockWebSocket.mockEngine.recordedInputPayload(
                Stream_Video_Sfu_Event_HealthCheckRequest.self,
                for: .sendMessage
            )
        )

        XCTAssertNil(input.first)
    }

    // MARK: - updateTrackMuteState

    func test_updateTrackMuteState_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        
        try await subject.updateTrackMuteState(
            .audio,
            isMuted: true,
            for: sessionID
        )

        let request = try XCTUnwrap(mockService.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.muteStates.endIndex, 1)
        XCTAssertEqual(request.sessionID, sessionID)

        let muteState = try XCTUnwrap(request.muteStates.first)
        XCTAssertEqual(muteState.trackType, .audio)
        XCTAssertTrue(muteState.muted)
    }

    // MARK: - sendStats

    func test_sendStats_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique

        try await subject.sendStats(
            .dummy(),
            for: sessionID
        )

        let request = try XCTUnwrap(mockService.sendStatsWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.sdk, "stream-ios")
        XCTAssertEqual(request.sdkVersion, SystemEnvironment.version)
        XCTAssertEqual(request.webrtcVersion, SystemEnvironment.webRTCVersion)
    }

    // MARK: - toggleNoiseCancellation

    func test_toggleNoiseCancellation_enabled_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique

        // When
        try await subject.toggleNoiseCancellation(true, for: sessionID)

        // Then
        let request = try XCTUnwrap(mockService.startNoiseCancellationWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    func test_toggleNoiseCancellation_disabled_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique

        // When
        try await subject.toggleNoiseCancellation(false, for: sessionID)

        // Then
        let request = try XCTUnwrap(mockService.stopNoiseCancellationWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    // MARK: - setPublisher

    func test_setPublisher_serviceWasCalledWithCorrectRequest() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionDescription = String.unique
        let sessionID = String.unique

        // When
        _ = try await subject.setPublisher(
            sessionDescription: sessionDescription,
            tracks: [],
            for: sessionID
        )

        // Then
        let request = try XCTUnwrap(mockService.setPublisherWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.sdp, sessionDescription)
    }

    // MARK: - updateSubscriptions

    func test_updateSubscriptions_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique

        // When
        _ = try await subject.updateSubscriptions(
            tracks: [],
            for: sessionID
        )

        // Then
        let request = try XCTUnwrap(mockService.updateSubscriptionsWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    // MARK: - sendAnswer

    func test_sendAnswer_serviceWasCalledWithCorrectRequest() async throws {
        let sessionDescription = String.unique
        let sessionID = String.unique

        // When
        _ = try await subject.sendAnswer(
            sessionDescription: sessionDescription,
            peerType: .subscriber,
            for: sessionID
        )

        // Then
        let request = try XCTUnwrap(mockService.sendAnswerWasCalledWithRequest)
        XCTAssertEqual(request.sdp, sessionDescription)
        XCTAssertEqual(request.peerType, .subscriber)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    // MARK: - iCETrickle

    func test_iCETrickle_serviceWasCalledWithCorrectRequest() async throws {
        let candidate = String.unique
        let sessionID = String.unique

        // When
        _ = try await subject.iCETrickle(
            candidate: candidate,
            peerType: .subscriber,
            for: sessionID
        )

        // Then
        let request = try XCTUnwrap(mockService.iCETrickleWasCalledWithRequest)
        XCTAssertEqual(request.iceCandidate, candidate)
        XCTAssertEqual(request.peerType, .subscriber)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    // MARK: - webSocketClient(_:didUpdateConnectionState:)

    func test_didUpdateConnectionState_connectionStateWasUpdated() {
        [
            WebSocketConnectionState.initialized,
            .disconnected(source: .systemInitiated),
            .connecting,
            .authenticating,
            .connected(healthCheckInfo: .init()),
            .disconnecting(source: .userInitiated)
        ].forEach { state in
            subject.webSocketClient(mockWebSocket, didUpdateConnectionState: state)

            XCTAssertEqual(subject.connectionState, state)
        }
    }
}
