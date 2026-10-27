//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// UnblockUserRequest is the payload for unblocking a user.
public final class UnblockUserRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// the user to unblock
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

extension UnblockUserRequest: Hashable {
    public static func == (lhs: UnblockUserRequest, rhs: UnblockUserRequest) -> Bool {
        lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
