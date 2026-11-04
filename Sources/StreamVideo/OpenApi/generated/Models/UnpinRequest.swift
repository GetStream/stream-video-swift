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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.userId = try container.decode(String.self, forKey: .userId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(userId, forKey: .userId)
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
