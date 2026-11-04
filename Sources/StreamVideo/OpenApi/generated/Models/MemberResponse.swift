//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// MemberResponse is the payload for a member of a call.
public final class MemberResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    public var createdAt: Date
    /// Custom member response data
    public var custom: [String: RawJSON]
    /// Date/time of deletion
    public var deletedAt: Date?
    public var role: String?
    /// Date/time of the last update
    public var updatedAt: Date
    /// User response object
    public var user: UserResponse
    public var userId: String

    public init(
        createdAt: Date,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        role: String? = nil,
        updatedAt: Date,
        user: UserResponse,
        userId: String
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.role = role
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case role
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}

extension MemberResponse: Hashable {
    public static func == (lhs: MemberResponse, rhs: MemberResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.role == rhs.role &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(role)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
