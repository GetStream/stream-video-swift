//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class UserEventPayload: @unchecked Sendable, Decodable {
    public var blockedUserIds: [String]
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    public var deletedAt: Date?
    public var id: String
    public var image: String?
    public var invisible: Bool?
    public var language: String
    public var lastActive: Date?
    public var name: String?
    public var role: String
    public var teams: [String]
    public var updatedAt: Date

    public init(
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
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
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.name = name
        self.role = role
        self.teams = teams
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.blockedUserIds = try container.decode([String].self, forKey: .blockedUserIds)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible)
        self.language = try container.decode(String.self, forKey: .language)
        self.lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.role = try container.decode(String.self, forKey: .role)
        self.teams = try container.decode([String].self, forKey: .teams)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

extension UserEventPayload: Hashable {
    public static func == (lhs: UserEventPayload, rhs: UserEventPayload) -> Bool {
        lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.invisible == rhs.invisible &&
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
        hasher.combine(invisible)
        hasher.combine(language)
        hasher.combine(lastActive)
        hasher.combine(name)
        hasher.combine(role)
        hasher.combine(teams)
        hasher.combine(updatedAt)
    }
}
