//
// OwnUserResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct OwnUserResponse: Codable, JSONEncodable, Hashable {
    public var banned: Bool
    public var channelMutes: [ChannelMute]
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    public var deletedAt: Date?
    public var devices: [Device]
    public var id: String
    public var image: String?
    public var invisible: Bool?
    public var language: String
    public var lastActive: Date?
    public var latestHiddenChannels: [String]?
    public var mutes: [UserMute]
    public var name: String?
    public var online: Bool
    public var privacySettings: PrivacySettings?
    public var pushNotifications: PushNotificationSettings?
    public var revokeTokensIssuedBefore: Date?
    public var role: String
    public var teams: [String]
    public var totalUnreadCount: Int
    public var unreadChannels: Int
    public var unreadThreads: Int
    public var updatedAt: Date

    public init(banned: Bool, channelMutes: [ChannelMute], createdAt: Date, custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, devices: [Device], id: String, image: String? = nil, invisible: Bool? = nil, language: String, lastActive: Date? = nil, latestHiddenChannels: [String]? = nil, mutes: [UserMute], name: String? = nil, online: Bool, privacySettings: PrivacySettings? = nil, pushNotifications: PushNotificationSettings? = nil, revokeTokensIssuedBefore: Date? = nil, role: String, teams: [String], totalUnreadCount: Int, unreadChannels: Int, unreadThreads: Int, updatedAt: Date) {
        self.banned = banned
        self.channelMutes = channelMutes
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.devices = devices
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.latestHiddenChannels = latestHiddenChannels
        self.mutes = mutes
        self.name = name
        self.online = online
        self.privacySettings = privacySettings
        self.pushNotifications = pushNotifications
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.teams = teams
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case channelMutes = "channel_mutes"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case devices
        case id
        case image
        case invisible
        case language
        case lastActive = "last_active"
        case latestHiddenChannels = "latest_hidden_channels"
        case mutes
        case name
        case online
        case privacySettings = "privacy_settings"
        case pushNotifications = "push_notifications"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case totalUnreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(banned, forKey: .banned)
        try container.encode(channelMutes, forKey: .channelMutes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deactivatedAt, forKey: .deactivatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(devices, forKey: .devices)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(invisible, forKey: .invisible)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(lastActive, forKey: .lastActive)
        try container.encodeIfPresent(latestHiddenChannels, forKey: .latestHiddenChannels)
        try container.encode(mutes, forKey: .mutes)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(online, forKey: .online)
        try container.encodeIfPresent(privacySettings, forKey: .privacySettings)
        try container.encodeIfPresent(pushNotifications, forKey: .pushNotifications)
        try container.encodeIfPresent(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encode(role, forKey: .role)
        try container.encode(teams, forKey: .teams)
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        try container.encode(unreadChannels, forKey: .unreadChannels)
        try container.encode(unreadThreads, forKey: .unreadThreads)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

