//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest
import SwiftProtobuf

final class CallController_Tests: ControllerTestCase {

    private var webRTCClient: WebRTCClient!
    
    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    
    public override func setUp() {
        super.setUp()
        streamVideo = StreamVideo(apiKey: apiKey, user: user, token: StreamVideo.mockToken, videoConfig: videoConfig)
    }

    func test_callController_joinCall_webRTCClientSignalChannelUsesTheExpectedConnectURL() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)

        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )

        // Then
        XCTAssertEqual(webRTCClient.signalChannel?.connectURL.absoluteString, "wss://test.com/ws")
    }

    func test_callController_reconnectionSuccess() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
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
    
    func test_callController_reconnectionFailure() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        webRTCClient.signalChannel?.connect()
        try await waitForCallEvent()
        let signalChannel = webRTCClient.signalChannel!
        let engine = signalChannel.engine as! WebSocketEngine_Mock
        engine.simulateConnectionSuccess()
        try await waitForCallEvent()
        engine.simulateDisconnect()
        callCoordinator.error = ClientError.NetworkError()
        try await waitForCallEvent()
        
        // Then
        XCTAssert(callController.call?.state.reconnectionStatus == .reconnecting)
     
        // When
        try await waitForCallEvent(nanoseconds: 5_000_000_000)
        
        // Then
        XCTAssert(callController.call == nil)
    }
    
    func test_callController_updateCallInfo() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        callController.update(
            callData: CallData(
                callCid: callCid,
                members: [],
                blockedUsers: [],
                createdAt: Date(),
                backstage: true,
                broadcasting: false,
                recording: false,
                updatedAt: Date(),
                hlsPlaylistUrl: "",
                autoRejectTimeout: 15000,
                customData: [:],
                createdBy: .anonymous
            )
        )
        
        // Then
        XCTAssert(callController.call?.state.callData?.backstage == true)
    }
    
    func test_callController_updateCallInfoDifferentCallCid() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        callController.update(
            callData: CallData(
                callCid: "default:different",
                members: [],
                blockedUsers: [],
                createdAt: Date(),
                backstage: true,
                broadcasting: false,
                recording: false,
                updatedAt: Date(),
                hlsPlaylistUrl: "",
                autoRejectTimeout: 15000,
                customData: [:],
                createdBy: .anonymous
            )
        )
        
        // Then
        XCTAssert(callController.call?.state.callData?.backstage == nil)
    }
    
    @MainActor
    func test_callController_updateRecordingState() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        let event = CallRecordingStartedEvent(callCid: callCid, createdAt: Date())
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callController.call?.state.recordingState == .recording)
    }
    
    @MainActor
    func test_callController_updateRecordingStateDifferentCallCid() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        let event = CallRecordingStartedEvent(callCid: "test", createdAt: Date())
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callController.call?.state.recordingState == .noRecording)
    }
    
    func test_callController_cleanup() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.call(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            members: []
        )
        callController.call = call
        callController.cleanUp()
        
        // Then
        XCTAssert(callController.call == nil)
    }
    
    // MARK: - private
    
    private func makeCallController(callCoordinator: CallCoordinatorController_Mock) -> CallController {
        let defaultAPI = DefaultAPI(
            basePath: "example.com",
            transport: URLSessionTransport(urlSession: URLSession.shared),
            middlewares: []
        )
        let callController = CallController(
            defaultAPI: defaultAPI,
            callCoordinatorController: callCoordinator,
            user: user,
            callId: callId,
            callType: callType,
            apiKey: apiKey,
            videoConfig: videoConfig,
            environment: .mock(with: webRTCClient)
        )
        return callController
    }
    
    private func makeWebRTCClient(callCoordinator: CallCoordinatorController_Mock) -> WebRTCClient {
        let time = VirtualTime()
        VirtualTimeTimer.time = time
        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self
        
        let webRTCClient = WebRTCClient(
            user: StreamVideo.mockUser,
            apiKey: StreamVideo.apiKey,
            hostname: "test.com",
            webSocketURLString: "wss://test.com/ws",
            token: StreamVideo.mockToken.rawValue,
            callCid: self.callCid,
            callCoordinatorController: callCoordinator,
            videoConfig: VideoConfig(),
            audioSettings: AudioSettings(
                accessRequestEnabled: true,
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
            webRTCBuilder: { _, _, _, _, _, _, _, _, _, _ in
            webRTCClient
        },
            sfuReconnectionTime: 5
        )
    }
    
}
