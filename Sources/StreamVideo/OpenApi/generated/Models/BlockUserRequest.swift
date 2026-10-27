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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.userId = try container.decode(String.self, forKey: .userId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(userId, forKey: .userId)
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
