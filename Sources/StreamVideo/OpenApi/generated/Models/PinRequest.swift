//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// PinRequest is the payload for pinning a message.
public final class PinRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// the session ID of the user who pinned the message
    public var sessionId: String
    /// the user ID of the user who pinned the message
    public var userId: String

    public init(sessionId: String, userId: String) {
        self.sessionId = sessionId
        self.userId = userId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(userId, forKey: .userId)
    }
}

extension PinRequest: Hashable {
    public static func == (lhs: PinRequest, rhs: PinRequest) -> Bool {
        lhs.sessionId == rhs.sessionId &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
        hasher.combine(userId)
    }
}
