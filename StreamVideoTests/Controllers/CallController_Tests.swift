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
    
    // MARK: - private
    
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
