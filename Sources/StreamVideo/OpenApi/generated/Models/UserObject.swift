//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserObject: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var banExpires: Date? = nil
    public var banned: Bool
    public var createdAt: Date? = nil
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date? = nil
    public var deletedAt: Date? = nil
    public var id: String
    public var invisible: Bool? = nil
    public var language: String? = nil
    public var lastActive: Date? = nil
    public var online: Bool
    public var privacySettings: PrivacySettings? = nil
    public var pushNotifications: PushNotificationSettings? = nil
    public var revokeTokensIssuedBefore: Date? = nil
    public var role: String
    public var teams: [String]? = nil
    public var updatedAt: Date? = nil

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
