//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class KickUserRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var block: Bool?
    public var userId: String

    public init(block: Bool? = nil, userId: String) {
        self.block = block
        self.userId = userId
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case block
    case userId = "user_id"
}

    public static func == (lhs: KickUserRequest, rhs: KickUserRequest) -> Bool {
        lhs.block == rhs.block &&
        lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(block)
        hasher.combine(userId)
    }
}
