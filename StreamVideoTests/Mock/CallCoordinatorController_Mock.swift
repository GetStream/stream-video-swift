//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallCoordinatorController_Mock: CallCoordinatorController {
    
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
    
}
