//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest
import SwiftProtobuf

@MainActor
final class CallController_Tests: ControllerTestCase {

    private var webRTCClient: WebRTCClient!
    
    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    
    public override func setUp() {
        super.setUp()
        streamVideo = StreamVideo(
            apiKey: apiKey,
            user: user,
            token: StreamVideo.mockToken,
            videoConfig: videoConfig,
            tokenProvider: { _ in }
        )
    }

    func test_callController_joinCall_webRTCClientSignalChannelUsesTheExpectedConnectURL() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController()

        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )

        // Then
        XCTAssertEqual(webRTCClient.signalChannel?.connectURL.absoluteString, "wss://test.com/ws")
    }

    func test_callController_reconnectionSuccess() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController(shouldReconnect: true)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        webRTCClient.signalChannel?.connect()
        try await waitForCallEvent()
        let signalChannel = webRTCClient.signalChannel!
        let engine = signalChannel.engine as! WebSocketEngine_Mock
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        engine.simulateDisconnect()
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .reconnecting)
     
        // When
        try await waitForCallEvent()
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        webRTCClient?.webSocketClient(
            signalChannel,
            didUpdateConnectionState: .connected(
                healthCheckInfo: HealthCheckInfo(
                    sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse()
                )
            )
        )
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .connected)
    }
    
    func test_callController_migrationSuccess() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController(shouldReconnect: true)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        webRTCClient.signalChannel?.connect()
        try await waitForCallEvent()
        let signalChannel = webRTCClient.signalChannel!
        let engine = signalChannel.engine as! WebSocketEngine_Mock
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.goAway(Stream_Video_Sfu_Event_GoAway())))
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .migrating)
     
        // When
        try await waitForCallEvent()
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        webRTCClient?.webSocketClient(
            signalChannel,
            didUpdateConnectionState: .connected(
                healthCheckInfo: HealthCheckInfo(
                    sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse()
                )
            )
        )
        webRTCClient?.onSessionMigrationCompleted?()
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .connected)
    }
    
    func test_callController_reconnectionFailure() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        webRTCClient.signalChannel?.connect()
        try await waitForCallEvent()
        let signalChannel = webRTCClient.signalChannel!
        let engine = signalChannel.engine as! WebSocketEngine_Mock
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        engine.simulateDisconnect()
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .reconnecting)
     
        // When
        try await waitForCallEvent(nanoseconds: 5_500_000_000)
        
        // Then
        XCTAssert(callController.call == nil)
    }
    
    func test_callController_updateCallInfo() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        var callResponse = MockResponseBuilder().makeCallResponse(cid: callCid)
        callResponse.backstage = true
        call?.state.update(from: callResponse)
        
        // Then
        XCTAssert(callController.call?.state.backstage == true)
    }
    
    @MainActor
    func test_callController_updateRecordingState() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController(recording: true)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        let event = CallRecordingStartedEvent(callCid: callCid, createdAt: Date())
        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRecordingStartedEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callController.call?.state.recordingState == .recording)
    }
    
    @MainActor
    func test_callController_updateRecordingStateDifferentCallCid() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        let event = CallRecordingStartedEvent(callCid: "test", createdAt: Date())
        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRecordingStartedEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callController.call?.state.recordingState == .noRecording)
    }
    
    func test_callController_cleanup() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        callController.cleanUp()
        
        // Then
        XCTAssert(callController.call == nil)
    }
    
    func test_callController_changeAudioState() async throws {
        // Given
        webRTCClient = try makeWebRTCClientWithMuteStatesResponse()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        try await callController.changeAudioState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.audioOn == false)
    }
    
    func test_callController_changeVideoState() async throws {
        // Given
        webRTCClient = try makeWebRTCClientWithMuteStatesResponse()
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        try await callController.changeVideoState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.videoOn == false)
    }
    
    func test_callController_changeTrackVisibility() async throws {
        // Given
        let sessionId = "test"
        webRTCClient = makeWebRTCClient()
        let participant = CallParticipant.dummy(id: sessionId)
        await webRTCClient.state.update(callParticipants: [sessionId: participant])
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        await callController.changeTrackVisibility(for: participant, isVisible: true)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[sessionId]
        XCTAssert(updated?.showTrack == true)
    }
    
    func test_callController_updateTrackSize() async throws {
        // Given
        let sessionId = "test"
        let size = CGSize(width: 100, height: 100)
        webRTCClient = makeWebRTCClient()
        let participant = CallParticipant.dummy(id: sessionId)
        await webRTCClient.state.update(callParticipants: [sessionId: participant])
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        await callController.updateTrackSize(size, for: participant)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[sessionId]
        XCTAssert(updated?.trackSize == size)
    }
    
    func test_callController_pinAndUnpin() async throws {
        // Given
        let sessionId = "test"
        webRTCClient = makeWebRTCClient()
        let participant = CallParticipant.dummy(id: sessionId)
        await webRTCClient.state.update(callParticipants: [sessionId: participant])
        let callController = makeCallController()
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            options: nil
        )
        callController.call = call
        try await callController.changePinState(isEnabled: true, sessionId: sessionId)
        
        // Then
        var updated = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(updated?.pin)
        XCTAssertEqual(updated?.pin?.isLocal, true)
        
        // When
        try await callController.changePinState(isEnabled: false, sessionId: sessionId)
        
        // Then
        updated = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNil(updated?.pin)
    }
    
    // MARK: - private
    
    private func makeCallController(
        shouldReconnect: Bool = false,
        recording: Bool = false
    ) -> CallController {
        let httpClient = HTTPClient_Mock()
        let joinCallResponse = MockResponseBuilder().makeJoinCallResponse(cid: callCid, recording: recording)
        let data = try! JSONEncoder.default.encode(joinCallResponse)
        var responses = [data]
        if shouldReconnect {
            responses.append(data)
        }
        httpClient.dataResponses = responses
        let defaultAPI = DefaultAPI(
            basePath: "example.com",
            transport: httpClient,
            middlewares: []
        )
        let callController = CallController(
            defaultAPI: defaultAPI,
            user: user,
            callId: callId,
            callType: callType,
            apiKey: apiKey,
            videoConfig: videoConfig,
            cachedLocation: nil,
            environment: .mock(with: webRTCClient)
        )
        return callController
    }
    
    private func makeWebRTCClientWithMuteStatesResponse() throws -> WebRTCClient {
        let response = try Stream_Video_Sfu_Signal_UpdateMuteStatesResponse().serializedData()
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = [response]
        return makeWebRTCClient(httpClient: httpClient)
    }
    
    private func makeWebRTCClient(httpClient: HTTPClient_Mock? = nil) -> WebRTCClient {
        let time = VirtualTime()
        VirtualTimeTimer.time = time
        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self
        if let httpClient {
            environment.httpClientBuilder = {
                httpClient
            }
        }
        
        let webRTCClient = WebRTCClient(
            user: StreamVideo.mockUser,
            apiKey: StreamVideo.apiKey,
            hostname: "test.com",
            webSocketURLString: "wss://test.com/ws",
            token: StreamVideo.mockToken.rawValue,
            callCid: self.callCid,
            sessionID: nil,
            ownCapabilities: [.sendAudio, .sendVideo],
            videoConfig: VideoConfig(),
            audioSettings: AudioSettings(
                accessRequestEnabled: true,
                defaultDevice: .speaker,
                micDefaultOn: true,
                opusDtxEnabled: true,
                redundantCodingEnabled: true,
                speakerDefaultOn: true
            ),
            environment: environment
        )
        return webRTCClient
    }

}

extension CallController.Environment {
    
    static func mock(with webRTCClient: WebRTCClient) -> Self {
        .init(
            webRTCBuilder: { _, _, _, _, _, _, _, _, _, _,_  in
            webRTCClient
        },
            sfuReconnectionTime: 5
        )
    }
    
}
