//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** Represents chat user */
internal struct UserObject: Codable, JSONEncodable, Hashable {

    /** Expiration date of the ban */
    internal var banExpires: Date?
    /** Whether a user is banned or not */
    internal var banned: Bool?
    /** Date/time of creation */
    internal var createdAt: Date?
    /** Date of deactivation */
    internal var deactivatedAt: Date?
    /** Date/time of deletion */
    internal var deletedAt: Date?
    /** Unique user identifier */
    internal var id: String
    internal var invisible: Bool?
    /** Preferred language of a user */
    internal var language: String?
    /** Date of last activity */
    internal var lastActive: Date?
    /** Whether a user online or not */
    internal var online: Bool?
    internal var pushNotifications: PushNotificationSettings?
    /** Revocation date for tokens */
    internal var revokeTokensIssuedBefore: Date?
    /** Determines the set of user permissions */
    internal var role: String?
    /** List of teams user is a part of */
    internal var teams: [String]?
    /** Date/time of the last update */
    internal var updatedAt: Date?

    internal init(
        banExpires: Date? = nil,
        banned: Bool? = nil,
        createdAt: Date? = nil,
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        invisible: Bool? = nil,
        language: String? = nil,
        lastActive: Date? = nil,
        online: Bool? = nil,
        pushNotifications: PushNotificationSettings? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String? = nil,
        teams: [String]? = nil,
        updatedAt: Date? = nil
    ) {
        self.banExpires = banExpires
        self.banned = banned
        self.createdAt = createdAt
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

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        case banned
        case createdAt = "created_at"
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

    internal var additionalProperties: [String: AnyCodable] = [:]

    internal subscript(key: String) -> AnyCodable? {
        get {
            if let value = additionalProperties[key] {
                return value
            }
            return nil
        }

        set {
            additionalProperties[key] = newValue
        }
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(banExpires, forKey: .banExpires)
        try container.encodeIfPresent(banned, forKey: .banned)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(deactivatedAt, forKey: .deactivatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(invisible, forKey: .invisible)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(lastActive, forKey: .lastActive)
        try container.encodeIfPresent(online, forKey: .online)
        try container.encodeIfPresent(pushNotifications, forKey: .pushNotifications)
        try container.encodeIfPresent(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(teams, forKey: .teams)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        var additionalPropertiesContainer = encoder.container(keyedBy: String.self)
        try additionalPropertiesContainer.encodeMap(additionalProperties)
    }

    // Decodable protocol methods

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        banExpires = try container.decodeIfPresent(Date.self, forKey: .banExpires)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        id = try container.decode(String.self, forKey: .id)
        invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        online = try container.decodeIfPresent(Bool.self, forKey: .online)
        pushNotifications = try container.decodeIfPresent(PushNotificationSettings.self, forKey: .pushNotifications)
        revokeTokensIssuedBefore = try container.decodeIfPresent(Date.self, forKey: .revokeTokensIssuedBefore)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        teams = try container.decodeIfPresent([String].self, forKey: .teams)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        var nonAdditionalPropertyKeys = Set<String>()
        nonAdditionalPropertyKeys.insert("ban_expires")
        nonAdditionalPropertyKeys.insert("banned")
        nonAdditionalPropertyKeys.insert("created_at")
        nonAdditionalPropertyKeys.insert("deactivated_at")
        nonAdditionalPropertyKeys.insert("deleted_at")
        nonAdditionalPropertyKeys.insert("id")
        nonAdditionalPropertyKeys.insert("invisible")
        nonAdditionalPropertyKeys.insert("language")
        nonAdditionalPropertyKeys.insert("last_active")
        nonAdditionalPropertyKeys.insert("online")
        nonAdditionalPropertyKeys.insert("push_notifications")
        nonAdditionalPropertyKeys.insert("revoke_tokens_issued_before")
        nonAdditionalPropertyKeys.insert("role")
        nonAdditionalPropertyKeys.insert("teams")
        nonAdditionalPropertyKeys.insert("updated_at")
        let additionalPropertiesContainer = try decoder.container(keyedBy: String.self)
        additionalProperties = try additionalPropertiesContainer.decodeMap(AnyCodable.self, excludedKeys: nonAdditionalPropertyKeys)
    }
}
