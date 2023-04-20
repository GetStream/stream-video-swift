//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallCoordinatorController_Mock: CallCoordinatorController {
    
    var error: Error?
    
    override func sendEvent(
        type: EventType,
        callId: String,
        callType: CallType,
        customData: [String: AnyCodable]? = nil
    ) async throws {
        // No op
    }
    
    override func createGuestUser(with id: String) async throws -> CreateGuestResponse {
        CreateGuestResponse(
            accessToken: StreamVideo.mockToken.rawValue,
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
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions,
        participants: [User],
        ring: Bool
    ) async throws -> EdgeServer {
        if let error {
            throw error
        }
        let callSettingsResponse = MockResponseBuilder().makeCallSettingsResponse()
        let callInfo = CallInfo(cId: "default:123", backstage: false, blockedUsers: [])
        let callSettingsInfo = CallSettingsInfo(
            callCapabilities: ["send-audio"],
            callSettings: callSettingsResponse,
            callInfo: callInfo,
            recording: false
        )
        return EdgeServer(
            url: "test.com",
            token: StreamVideo.mockToken.rawValue,
            iceServers: [],
            callSettings: callSettingsInfo,
            latencyURL: nil
        )
    }
    
    func update(callSettings: CallSettingsInfo) {
        self.currentCallSettings = callSettings
    }
    
}
