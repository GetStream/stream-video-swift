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
    
}
