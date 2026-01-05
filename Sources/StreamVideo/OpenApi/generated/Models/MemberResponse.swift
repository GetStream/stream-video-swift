//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class MemberResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deletedAt: Date?
    public var role: String?
    public var updatedAt: Date
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case role
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
    
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
