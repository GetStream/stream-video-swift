//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserObject: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    public var privacySettings: PrivacySettings?
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
        privacySettings: PrivacySettings? = nil,
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
        self.privacySettings = privacySettings
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
        case privacySettings = "privacy_settings"
        case pushNotifications = "push_notifications"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case updatedAt = "updated_at"
    }
}
