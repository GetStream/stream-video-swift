//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ChannelResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var autoTranslationEnabled: Bool? = nil
    public var autoTranslationLanguage: String? = nil
    public var blocked: Bool? = nil
    public var cid: String
    public var config: ChannelConfigWithInfo? = nil
    public var cooldown: Int? = nil
    public var createdAt: Date
    public var createdBy: UserObject? = nil
    public var custom: [String: RawJSON]
    public var deletedAt: Date? = nil
    public var disabled: Bool
    public var frozen: Bool
    public var hidden: Bool? = nil
    public var hideMessagesBefore: Date? = nil
    public var id: String
    public var lastMessageAt: Date? = nil
    public var memberCount: Int? = nil
    public var members: [ChannelMember?]? = nil
    public var muteExpiresAt: Date? = nil
    public var muted: Bool? = nil
    public var ownCapabilities: [String]? = nil
    public var team: String? = nil
    public var truncatedAt: Date? = nil
    public var truncatedBy: UserObject? = nil
    public var type: String
    public var updatedAt: Date

    public init(
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil,
        blocked: Bool? = nil,
        cid: String,
        config: ChannelConfigWithInfo? = nil,
        cooldown: Int? = nil,
        createdAt: Date,
        createdBy: UserObject? = nil,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        disabled: Bool,
        frozen: Bool,
        hidden: Bool? = nil,
        hideMessagesBefore: Date? = nil,
        id: String,
        lastMessageAt: Date? = nil,
        memberCount: Int? = nil,
        members: [ChannelMember?]? = nil,
        muteExpiresAt: Date? = nil,
        muted: Bool? = nil,
        ownCapabilities: [String]? = nil,
        team: String? = nil,
        truncatedAt: Date? = nil,
        truncatedBy: UserObject? = nil,
        type: String,
        updatedAt: Date
    ) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.blocked = blocked
        self.cid = cid
        self.config = config
        self.cooldown = cooldown
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.deletedAt = deletedAt
        self.disabled = disabled
        self.frozen = frozen
        self.hidden = hidden
        self.hideMessagesBefore = hideMessagesBefore
        self.id = id
        self.lastMessageAt = lastMessageAt
        self.memberCount = memberCount
        self.members = members
        self.muteExpiresAt = muteExpiresAt
        self.muted = muted
        self.ownCapabilities = ownCapabilities
        self.team = team
        self.truncatedAt = truncatedAt
        self.truncatedBy = truncatedBy
        self.type = type
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case blocked
        case cid
        case config
        case cooldown
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case deletedAt = "deleted_at"
        case disabled
        case frozen
        case hidden
        case hideMessagesBefore = "hide_messages_before"
        case id
        case lastMessageAt = "last_message_at"
        case memberCount = "member_count"
        case members
        case muteExpiresAt = "mute_expires_at"
        case muted
        case ownCapabilities = "own_capabilities"
        case team
        case truncatedAt = "truncated_at"
        case truncatedBy = "truncated_by"
        case type
        case updatedAt = "updated_at"
    }
}
