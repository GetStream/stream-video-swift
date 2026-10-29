//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// KickUserRequest is the payload for kicking a user from a call. Optionally block the user as well.
public final class KickUserRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// If true, also block the user from rejoining the call
    public var block: Bool?
    /// The user to kick
    public var userId: String

    public init(block: Bool? = nil, userId: String) {
        self.block = block
        self.userId = userId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.block = try container.decodeIfPresent(Bool.self, forKey: .block)
        self.userId = try container.decode(String.self, forKey: .userId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(block, forKey: .block)
        try container.encode(userId, forKey: .userId)
    }
}

extension KickUserRequest: Hashable {
    public static func == (lhs: KickUserRequest, rhs: KickUserRequest) -> Bool {
        lhs.block == rhs.block &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(block)
        hasher.combine(userId)
    }
}
