//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallCoordinatorController_Mock: CallCoordinatorController {
    
    var error: Error?
    
    override func sendEvent(
        type: EventType,
        callId: String,
        callType: String,
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
        callType: String,
        callId: String,
        videoOptions: VideoOptions,
        members: [User],
        ring: Bool
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
            customData: [:]
        )
        let callSettingsInfo = CallSettingsInfo(
            callCapabilities: ["send-audio"],
            callSettings: callSettingsResponse,
            state: state,
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
