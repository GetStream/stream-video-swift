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
        ownCapabilities: [.sendAudio, .sendVideo],
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
        create: Bool = true,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        options: CreateCallOptions? = nil,
        migratingFrom: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            self?.call?.state.participants = participants
        }
        return mockResponseBuilder.makeJoinCallResponse(cid: "\(callType):\(callId)")
    }
    
    override func changeAudioState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeVideoState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        completion()
    }
    
}
