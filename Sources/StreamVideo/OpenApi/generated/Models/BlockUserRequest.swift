//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// BlockUserRequest is the payload for blocking a user.
public final class BlockUserRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// the user to block
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

extension BlockUserRequest: Hashable {
    public static func == (lhs: BlockUserRequest, rhs: BlockUserRequest) -> Bool {
        lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
