//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PinRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var sessionId: String
    public var userId: String

    public init(sessionId: String, userId: String) {
        self.sessionId = sessionId
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case sessionId = "session_id"
        case userId = "user_id"
    }
}
