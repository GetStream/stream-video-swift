//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

class CallController_Mock: CallController {
    
    let mockResponseBuilder = MockResponseBuilder()
            
    internal lazy var webRTCClient = WebRTCClient(
        user: StreamVideo.mockUser,
        apiKey: "key1",
        hostname: "localhost",
        webSocketURLString: "wss://localhost/ws",
        token: StreamVideo.mockToken.rawValue,
        callCid: "default:test",
        sessionID: nil,
        ownCapabilities: [.sendAudio, .sendVideo],
        videoConfig: .dummy(),
        audioSettings: AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .speaker,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
        ),
        environment: WebSocketClient.Environment.mock
    )
    
    @MainActor func update(participants: [String: CallParticipant]) {
        call?.state.participantsMap = participants
    }

    override func joinCall(
        create: Bool = true,
        callType: String,
        callId: String,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        migratingFrom: String? = nil,
        sessionID: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            executeOnMain {
                self?.call?.state.participantsMap = participants
            }
        }
        return mockResponseBuilder.makeJoinCallResponse(cid: "\(callType):\(callId)")
    }
    
    override func changeAudioState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeVideoState(isEnabled: Bool) async throws { /* no op */ }
        
    override func changeCameraMode(position: CameraPosition) async throws { /* no op */ }
    
    override func changeSoundState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeSpeakerState(isEnabled: Bool) async throws { /* no op */ }
}

extension CallController_Mock {
    static func make() -> CallController_Mock {
        CallController_Mock(
            defaultAPI: DefaultAPI(
                basePath: "test.com",
                transport: HTTPClient_Mock(),
                middlewares: []
            ),
            user: StreamVideo.mockUser,
            callId: "123",
            callType: "default",
            apiKey: "key1",
            videoConfig: .dummy(),
            cachedLocation: nil
        )
    }
}
