//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UnpinRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: UnpinRequest, rhs: UnpinRequest) -> Bool {
        lhs.sessionId == rhs.sessionId &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
        hasher.combine(userId)
    }
}
