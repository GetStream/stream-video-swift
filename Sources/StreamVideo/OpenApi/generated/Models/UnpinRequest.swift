//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// UnpinRequest is the payload for unpinning a message.
public final class UnpinRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// the session ID of the user who pinned the message
    public var sessionId: String
    /// the user ID of the user who pinned the message
    public var userId: String

    public init(sessionId: String, userId: String) {
        self.sessionId = sessionId
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userId = "user_id"
    }
}

extension UnpinRequest: Hashable {
    public static func == (lhs: UnpinRequest, rhs: UnpinRequest) -> Bool {
        lhs.sessionId == rhs.sessionId &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
        hasher.combine(userId)
    }
}
