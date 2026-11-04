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

    public enum CodingKeys: String, CodingKey {
        case block
        case userId = "user_id"
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
