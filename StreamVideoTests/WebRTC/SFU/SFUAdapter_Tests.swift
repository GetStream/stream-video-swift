//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    // MARK: - init

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

    func test_connect_eventWasPublished() async throws {
        await assertEventWasPublished(
            expected: SFUAdapter.ConnectEvent(hostname: mockService.hostname),
            operation: { subject.connect() }
        )
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

    func test_disconnect_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))

        await assertEventWasPublished(
            expected: SFUAdapter.DisconnectEvent(hostname: mockService.hostname),
            operation: { await subject.disconnect() }
        )
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

    func test_updateTrackMuteState_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        var payload = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        payload.sessionID = sessionID
        var muteState = Stream_Video_Sfu_Signal_TrackMuteState()
        muteState.trackType = .audio
        muteState.muted = true
        payload.muteStates = [muteState]

        try await assertEventWasPublished(
            expected: SFUAdapter.UpdateTrackMuteStateEvent(
                hostname: mockService.hostname,
                payload: payload
            ),
            operation: {
                try await subject.updateTrackMuteState(
                    .audio,
                    isMuted: true,
                    for: sessionID
                )
            }
        )
    }

    // MARK: - sendStats

    func test_sendStats_withoutThermalState_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        let unifiedSessionId = String.unique

        try await subject.sendStats(
            .dummy(),
            for: sessionID,
            unifiedSessionId: unifiedSessionId
        )

        let request = try XCTUnwrap(mockService.sendStatsWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(request.sdk, "stream-ios")
        XCTAssertEqual(request.sdkVersion, SystemEnvironment.version)
        XCTAssertEqual(request.webrtcVersion, SystemEnvironment.webRTCVersion)
        XCTAssertEqual(request.deviceState?.thermalState, .unspecified)
    }

    func test_sendStats_withThermalState_serviceWasCalledWithCorrectRequest() async throws {
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        let unifiedSessionId = String.unique

        try await subject.sendStats(
            .dummy(),
            for: sessionID,
            unifiedSessionId: unifiedSessionId,
            thermalState: .critical
        )

        let request = try XCTUnwrap(mockService.sendStatsWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(request.sdk, "stream-ios")
        XCTAssertEqual(request.sdkVersion, SystemEnvironment.version)
        XCTAssertEqual(request.webrtcVersion, SystemEnvironment.webRTCVersion)
        XCTAssertEqual(request.deviceState?.thermalState, .critical)
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

    func test_toggleNoiseCancellation_enabled_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Signal_StartNoiseCancellationRequest()
        request.sessionID = sessionID

        try await assertEventWasPublished(
            expected: SFUAdapter.StartNoiseCancellationEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                try await subject.toggleNoiseCancellation(true, for: sessionID)
            }
        )
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

    func test_toggleNoiseCancellation_disabled_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Signal_StopNoiseCancellationRequest()
        request.sessionID = sessionID

        try await assertEventWasPublished(
            expected: SFUAdapter.StopNoiseCancellationEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                try await subject.toggleNoiseCancellation(false, for: sessionID)
            }
        )
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

    func test_setPublisher_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        let sessionDescription = String.unique
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = sessionDescription
        request.sessionID = sessionID
        request.tracks = []

        try await assertEventWasPublished(
            expected: SFUAdapter.SetPublisherEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                _ = try await subject.setPublisher(
                    sessionDescription: sessionDescription,
                    tracks: [],
                    for: sessionID
                )
            }
        )
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

    func test_updateSubscriptions_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        request.sessionID = sessionID

        try await assertEventWasPublished(
            expected: SFUAdapter.UpdateSubscriptionsEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                _ = try await subject.updateSubscriptions(
                    tracks: [],
                    for: sessionID
                )
            }
        )
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

    func test_sendAnswer_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionDescription = String.unique
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Signal_SendAnswerRequest()
        request.sessionID = sessionID
        request.sdp = sessionDescription
        request.peerType = .subscriber

        try await assertEventWasPublished(
            expected: SFUAdapter.SendAnswerEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                _ = try await subject.sendAnswer(
                    sessionDescription: sessionDescription,
                    peerType: .subscriber,
                    for: sessionID
                )
            }
        )
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

    func test_iCETrickle_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let candidate = String.unique
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Models_ICETrickle()
        request.sessionID = sessionID
        request.iceCandidate = candidate
        request.peerType = .subscriber

        try await assertEventWasPublished(
            expected: SFUAdapter.ICETrickleEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                _ = try await subject.iCETrickle(
                    candidate: candidate,
                    peerType: .subscriber,
                    for: sessionID
                )
            }
        )
    }

    // MARK: - restartICE

    func test_restartICE_serviceWasCalledWithCorrectRequest() async throws {
        let sessionID = String.unique

        // When
        _ = try await subject.restartICE(
            for: sessionID,
            peerType: .subscriber
        )

        // Then
        let request = try XCTUnwrap(mockService.iceRestartWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.peerType, .subscriber)
    }

    func test_restartICE_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        let sessionID = String.unique
        var request = Stream_Video_Sfu_Signal_ICERestartRequest()
        request.sessionID = sessionID
        request.peerType = .subscriber

        try await assertEventWasPublished(
            expected: SFUAdapter.RestartICEEvent(
                hostname: mockService.hostname,
                payload: request
            ),
            operation: {
                _ = try await subject.restartICE(
                    for: sessionID,
                    peerType: .subscriber
                )
            }
        )
    }

    // MARK: - sendJoinRequest

    func test_sendJoinRequest_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        var payload = Stream_Video_Sfu_Event_JoinRequest()
        payload.sessionID = .unique

        await assertEventWasPublished(
            expected: SFUAdapter.JoinEvent(hostname: mockService.hostname, payload: payload),
            operation: { subject.sendJoinRequest(payload) }
        )
    }

    // MARK: - sendLeaveRequest

    func test_sendLeaveRequest_eventWasPublished() async throws {
        _ = subject
        mockWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        var payload = Stream_Video_Sfu_Event_LeaveCallRequest()
        payload.sessionID = .unique

        await assertEventWasPublished(
            expected: SFUAdapter.LeaveEvent(hostname: mockService.hostname, payload: payload),
            operation: { subject.sendLeaveRequest(for: payload.sessionID) }
        )
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

    // MARK: - Private Helpers

    private func assertEventWasPublished<Event: SFUAdapterEvent & Equatable>(
        expected: Event,
        operation: () async throws -> Void,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async rethrows {
        let expectation = self.expectation(description: "\(type(of: expected)) was not received.")

        let cancellable = subject
            .publisherSendEvent
            .compactMap { $0 as? Event }
            .filter { $0 == expected }
            .sink { _ in expectation.fulfill() }
        defer { cancellable.cancel() }

        try await operation()

        await safeFulfillment(of: [expectation], file: file, line: line)
    }
}
