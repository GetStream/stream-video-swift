//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserObject: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var banExpires: Date?
    public var banned: Bool
    public var createdAt: Date?
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    public var deletedAt: Date?
    public var id: String
    public var invisible: Bool?
    public var language: String?
    public var lastActive: Date?
    public var online: Bool
    public var pushNotifications: PushNotificationSettings?
    public var revokeTokensIssuedBefore: Date?
    public var role: String
    public var teams: [String]?
    public var updatedAt: Date?

    public init(
        banExpires: Date? = nil,
        banned: Bool,
        createdAt: Date? = nil,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        invisible: Bool? = nil,
        language: String? = nil,
        lastActive: Date? = nil,
        online: Bool,
        pushNotifications: PushNotificationSettings? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String]? = nil,
        updatedAt: Date? = nil
    ) {
        self.banExpires = banExpires
        self.banned = banned
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.id = id
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.online = online
        self.pushNotifications = pushNotifications
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.teams = teams
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        case banned
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case id
        case invisible
        case language
        case lastActive = "last_active"
        case online
        case pushNotifications = "push_notifications"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case updatedAt = "updated_at"
    }
    
    public static func == (lhs: UserObject, rhs: UserObject) -> Bool {
        lhs.banExpires == rhs.banExpires &&
            lhs.banned == rhs.banned &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.id == rhs.id &&
            lhs.invisible == rhs.invisible &&
            lhs.language == rhs.language &&
            lhs.lastActive == rhs.lastActive &&
            lhs.online == rhs.online &&
            lhs.pushNotifications == rhs.pushNotifications &&
            lhs.revokeTokensIssuedBefore == rhs.revokeTokensIssuedBefore &&
            lhs.role == rhs.role &&
            lhs.teams == rhs.teams &&
            lhs.updatedAt == rhs.updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(banExpires)
        hasher.combine(banned)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deactivatedAt)
        hasher.combine(deletedAt)
        hasher.combine(id)
        hasher.combine(invisible)
        hasher.combine(language)
        hasher.combine(lastActive)
        hasher.combine(online)
        hasher.combine(pushNotifications)
        hasher.combine(revokeTokensIssuedBefore)
        hasher.combine(role)
        hasher.combine(teams)
        hasher.combine(updatedAt)
    }
}
