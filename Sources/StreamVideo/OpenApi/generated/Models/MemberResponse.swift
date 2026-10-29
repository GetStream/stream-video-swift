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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decode(UserResponse.self, forKey: .user)
        self.userId = try container.decode(String.self, forKey: .userId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(user, forKey: .user)
        try container.encode(userId, forKey: .userId)
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
