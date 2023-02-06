//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** Represents chat user */
internal struct UserObjectRequest: Codable, JSONEncodable, Hashable {

    /** Expiration date of the ban */
    internal var banExpires: Date?
    /** Whether a user is banned or not */
    internal var banned: Bool?
    /** Unique user identifier */
    internal var id: String
    internal var invisible: Bool?
    /** Preferred language of a user */
    internal var language: String?
    internal var pushNotifications: PushNotificationSettingsRequest?
    /** Revocation date for tokens */
    internal var revokeTokensIssuedBefore: Date?
    /** Determines the set of user permissions */
    internal var role: String?
    /** List of teams user is a part of */
    internal var teams: [String]?

    internal init(
        banExpires: Date? = nil,
        banned: Bool? = nil,
        id: String,
        invisible: Bool? = nil,
        language: String? = nil,
        pushNotifications: PushNotificationSettingsRequest? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String? = nil,
        teams: [String]? = nil
    ) {
        self.banExpires = banExpires
        self.banned = banned
        self.id = id
        self.invisible = invisible
        self.language = language
        self.pushNotifications = pushNotifications
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.teams = teams
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        case banned
        case id
        case invisible
        case language
        case pushNotifications = "push_notifications"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
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
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(invisible, forKey: .invisible)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(pushNotifications, forKey: .pushNotifications)
        try container.encodeIfPresent(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(teams, forKey: .teams)
        var additionalPropertiesContainer = encoder.container(keyedBy: String.self)
        try additionalPropertiesContainer.encodeMap(additionalProperties)
    }

    // Decodable protocol methods

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        banExpires = try container.decodeIfPresent(Date.self, forKey: .banExpires)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        id = try container.decode(String.self, forKey: .id)
        invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        pushNotifications = try container.decodeIfPresent(PushNotificationSettingsRequest.self, forKey: .pushNotifications)
        revokeTokensIssuedBefore = try container.decodeIfPresent(Date.self, forKey: .revokeTokensIssuedBefore)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        teams = try container.decodeIfPresent([String].self, forKey: .teams)
        var nonAdditionalPropertyKeys = Set<String>()
        nonAdditionalPropertyKeys.insert("ban_expires")
        nonAdditionalPropertyKeys.insert("banned")
        nonAdditionalPropertyKeys.insert("id")
        nonAdditionalPropertyKeys.insert("invisible")
        nonAdditionalPropertyKeys.insert("language")
        nonAdditionalPropertyKeys.insert("push_notifications")
        nonAdditionalPropertyKeys.insert("revoke_tokens_issued_before")
        nonAdditionalPropertyKeys.insert("role")
        nonAdditionalPropertyKeys.insert("teams")
        let additionalPropertiesContainer = try decoder.container(keyedBy: String.self)
        additionalProperties = try additionalPropertiesContainer.decodeMap(AnyCodable.self, excludedKeys: nonAdditionalPropertyKeys)
    }
}
