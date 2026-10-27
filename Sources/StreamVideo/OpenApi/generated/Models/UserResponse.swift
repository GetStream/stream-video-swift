//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// User response object
public final class UserResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var blockedUserIds: [String]
    /// Date/time of creation
    public var createdAt: Date
    /// Custom data for this object
    public var custom: [String: RawJSON]
    /// Date of deactivation
    public var deactivatedAt: Date?
    /// Date/time of deletion
    public var deletedAt: Date?
    /// Unique user identifier
    public var id: String
    public var image: String?
    /// Preferred language of a user
    public var language: String
    /// Date of last activity
    public var lastActive: Date?
    /// Optional name of user
    public var name: String?
    /// Determines the set of user permissions
    public var role: String
    /// List of teams user is a part of
    public var teams: [String]
    /// Date/time of the last update
    public var updatedAt: Date

    public init(
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        role: String,
        teams: [String],
        updatedAt: Date
    ) {
        self.blockedUserIds = blockedUserIds
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.id = id
        self.image = image
        self.language = language
        self.lastActive = lastActive
        self.name = name
        self.role = role
        self.teams = teams
        self.updatedAt = updatedAt
    }

    public enum CodingKeys: String, CodingKey {
        case blockedUserIds = "blocked_user_ids"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case id
        case image
        case language
        case lastActive = "last_active"
        case name
        case role
        case teams
        case updatedAt = "updated_at"
    }
}

extension UserResponse: Hashable {
    public static func == (lhs: UserResponse, rhs: UserResponse) -> Bool {
        lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.language == rhs.language &&
            lhs.lastActive == rhs.lastActive &&
            lhs.name == rhs.name &&
            lhs.role == rhs.role &&
            lhs.teams == rhs.teams &&
            lhs.updatedAt == rhs.updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockedUserIds)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deactivatedAt)
        hasher.combine(deletedAt)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(language)
        hasher.combine(lastActive)
        hasher.combine(name)
        hasher.combine(role)
        hasher.combine(teams)
        hasher.combine(updatedAt)
    }
}
