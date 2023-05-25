//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallController_Mock: CallController {
    
    let mockResponseBuilder = MockResponseBuilder()
            
    internal lazy var webRTCClient = WebRTCClient(
        user: StreamVideo.mockUser,
        apiKey: "key1",
        hostname: "localhost",
        webSocketURLString: "wss://localhost/ws",
        token: StreamVideo.mockToken.rawValue,
        callCid: "default:test",
        callCoordinatorController: callCoordinatorController,
        videoConfig: VideoConfig(),
        audioSettings: AudioSettings(
            accessRequestEnabled: true,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
        ),
        environment: WebSocketClient.Environment.mock
    )

    override func joinCall(
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        members: [User],
        ring: Bool = false,
        notify: Bool = false
    ) async throws {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            self?.call?.participants = participants
        }
    }
    
    override func joinCall(
        on edgeServer: EdgeServer,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions
    ) async throws {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            self?.call?.participants = participants
        }
    }
    
    override func changeAudioState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeVideoState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        completion()
    }
    
    override func selectEdgeServer(
        videoOptions: VideoOptions,
        members: [User]
    ) async throws -> EdgeServer {
        EdgeServer(
            url: "localhost",
            webSocketURL: "wss://localhost/ws",
            token: "token",
            iceServers: [],
            callSettings: makeCallSettingsInfo(callId: "test", callType: .default),
            latencyURL: nil
        )
    }
    
    // MARK: - private
    
    func makeCallSettingsInfo(callId: String, callType: String) -> CallSettingsInfo {
        let state = CallData(
            callCid: callCid(from: callId, callType: callType),
            members: [],
            blockedUsers: [],
            createdAt: Date(),
            backstage: false,
            broadcasting: false,
            recording: false,
            updatedAt: Date(),
            hlsPlaylistUrl: "",
            autoRejectTimeout: 15000,
            customData: [:],
            createdBy: .anonymous
        )
        let callSettingsInfo = CallSettingsInfo(
            callCapabilities: [],
            callSettings: mockResponseBuilder.makeCallSettingsResponse(),
            state: state,
            recording: false
        )
        return callSettingsInfo
    }
    
}
