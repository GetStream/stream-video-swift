//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct OwnUser: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var banned: Bool
    public var blockedUserIds: [String]? = nil
    public var channelMutes: [ChannelMute?]
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date? = nil
    public var deletedAt: Date? = nil
    public var devices: [Device?]
    public var id: String
    public var invisible: Bool? = nil
    public var language: String
    public var lastActive: Date? = nil
    public var latestHiddenChannels: [String]? = nil
    public var mutes: [UserMute?]
    public var online: Bool
    public var privacySettings: PrivacySettings? = nil
    public var pushNotifications: PushNotificationSettings? = nil
    public var role: String
    public var teams: [String]? = nil
    public var totalUnreadCount: Int
    public var unreadChannels: Int
    public var unreadCount: Int
    public var unreadThreads: Int
    public var updatedAt: Date

    public init(
        banned: Bool,
        blockedUserIds: [String]? = nil,
        channelMutes: [ChannelMute?],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        devices: [Device?],
        id: String,
        invisible: Bool? = nil,
        language: String,
        lastActive: Date? = nil,
        latestHiddenChannels: [String]? = nil,
        mutes: [UserMute?],
        online: Bool,
        privacySettings: PrivacySettings? = nil,
        pushNotifications: PushNotificationSettings? = nil,
        role: String,
        teams: [String]? = nil,
        totalUnreadCount: Int,
        unreadChannels: Int,
        unreadCount: Int,
        unreadThreads: Int,
        updatedAt: Date
    ) {
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.channelMutes = channelMutes
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.devices = devices
        self.id = id
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.latestHiddenChannels = latestHiddenChannels
        self.mutes = mutes
        self.online = online
        self.privacySettings = privacySettings
        self.pushNotifications = pushNotifications
        self.role = role
        self.teams = teams
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case blockedUserIds = "blocked_user_ids"
        case channelMutes = "channel_mutes"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case devices
        case id
        case invisible
        case language
        case lastActive = "last_active"
        case latestHiddenChannels = "latest_hidden_channels"
        case mutes
        case online
        case privacySettings = "privacy_settings"
        case pushNotifications = "push_notifications"
        case role
        case teams
        case totalUnreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }
}
