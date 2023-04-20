//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest
import SwiftProtobuf

final class CallController_Tests: StreamVideoTestCase {
    
    let user = User(id: "test")
    let callId = "123"
    let callType = CallType.default
    let apiKey = "123"
    let videoConfig = VideoConfig()
    var callCid: String {
        "\(callType.name):\(callId)"
    }
    
    private var webRTCClient: WebRTCClient!
    
    public override func setUp() {
        super.setUp()
        streamVideo = StreamVideo(apiKey: apiKey, user: user, token: StreamVideo.mockToken, videoConfig: videoConfig)
    }

    func test_callController_reconnectionSuccess() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
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
        XCTAssert(callController.call?.reconnectionStatus == .reconnecting)
     
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
        XCTAssert(callController.call?.reconnectionStatus == .connected)
    }
    
    func test_callController_reconnectionFailure() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
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
        XCTAssert(callController.call?.reconnectionStatus == .reconnecting)
     
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
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
        )
        callController.call = call
        callController.update(callInfo: CallInfo(cId: callCid, backstage: true, blockedUsers: []))
        
        // Then
        XCTAssert(callController.call?.callInfo?.backstage == true)
    }
    
    func test_callController_updateCallInfoDifferentCallCid() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
        )
        callController.call = call
        callController.update(callInfo: CallInfo(cId: "default:different", backstage: true, blockedUsers: []))
        
        // Then
        XCTAssert(callController.call?.callInfo?.backstage == nil)
    }
    
    func test_callController_updateRecordingState() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
        )
        callController.call = call
        callController.updateCall(from: .init(callCid: callCid, type: "default", action: .started))
        
        // Then
        XCTAssert(callController.call?.recordingState == .recording)
    }
    
    func test_callController_updateRecordingStateDifferentCallCid() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
        )
        callController.call = call
        callController.updateCall(from: .init(callCid: "default:different", type: "default", action: .started))
        
        // Then
        XCTAssert(callController.call?.recordingState == .noRecording)
    }
    
    func test_callController_cleanup() async throws {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        webRTCClient = makeWebRTCClient(callCoordinator: callCoordinator)
        let callController = makeCallController(callCoordinator: callCoordinator)
        let call = streamVideo?.makeCall(callType: callType, callId: callId)
        
        // When
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            participants: []
        )
        callController.call = call
        callController.cleanUp()
        
        // Then
        XCTAssert(callController.call == nil)
    }
    
    // MARK: - private
    
    private func makeCallController(callCoordinator: CallCoordinatorController_Mock) -> CallController {
        let callController = CallController(
            callCoordinatorController: callCoordinator,
            user: user,
            callId: callId,
            callType: callType,
            apiKey: apiKey,
            videoConfig: videoConfig,
            allEventsMiddleware: nil,
            environment: .mock(with: webRTCClient)
        )
        return callController
    }
    
    private func makeCallCoordinatorController() -> CallCoordinatorController_Mock {
        let callCoordinator = CallCoordinatorController_Mock(
            httpClient: HTTPClient_Mock(),
            user: user,
            coordinatorInfo: CoordinatorInfo(
                apiKey: apiKey,
                hostname: "test.com",
                token: StreamVideo.mockToken.rawValue
            ),
            videoConfig: videoConfig
        )
        return callCoordinator
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
            token: StreamVideo.mockToken.rawValue,
            callCid: self.callCid,
            callCoordinatorController: callCoordinator,
            videoConfig: VideoConfig(),
            audioSettings: AudioSettings(
                accessRequestEnabled: true,
                opusDtxEnabled: true,
                redundantCodingEnabled: true
            ),
            environment: environment
        )
        return webRTCClient
    }

}

extension CallController.Environment {
    
    static func mock(with webRTCClient: WebRTCClient) -> Self {
        .init(
            webRTCBuilder: { _, _, _, _, _, _, _, _, _ in
            webRTCClient
        },
            sfuReconnectionTime: 5
        )
    }
    
}
