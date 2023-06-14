//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallCoordinatorController_Mock: CallCoordinatorController {
    
    var error: Error?
    
    override func sendEvent(
        callId: String,
        callType: String,
        customData: [String: RawJSON]? = nil
    ) async throws {
        // No op
    }
    
    override func createGuestUser(with id: String) async throws -> CreateGuestResponse {
        CreateGuestResponse(
            accessToken: StreamVideo.mockToken,
            duration: "",
            user: UserResponse(
                createdAt: Date(),
                custom: [:],
                id: StreamVideo.mockUser.id,
                role: "", teams: [],
                updatedAt: Date()
            )
        )
    }
    
    override func joinCall(
        callType: String,
        callId: String,
        videoOptions: VideoOptions,
        members: [User],
        ring: Bool,
        notify: Bool
    ) async throws -> EdgeServer {
        if let error {
            throw error
        }
        let callSettingsResponse = MockResponseBuilder().makeCallSettingsResponse()
        let state = CallData(
            callCid: "default:123",
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
        let callSettingsInfo = CallSettingsInfo(
            callCapabilities: ["send-audio"],
            callSettings: callSettingsResponse,
            state: state,
            recording: false
        )
        return EdgeServer(
            url: "test.com",
            webSocketURL: "wss://test.com/ws",
            token: StreamVideo.mockToken,
            iceServers: [],
            callSettings: callSettingsInfo,
            latencyURL: nil
        )
    }
    
    override func acceptCall(callId: String, type: String) async throws -> AcceptCallResponse {
        AcceptCallResponse(duration: "1.0")
    }
    
    override func rejectCall(callId: String, type: String) async throws -> RejectCallResponse {
        RejectCallResponse(duration: "1.0")
    }
    
    func update(callSettings: CallSettingsInfo) {
        self.currentCallSettings = callSettings
    }
    
}
