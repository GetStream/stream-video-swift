//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct OwnUserResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var banned: Bool
    public var blockedUserIds: [String]?
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    public var deletedAt: Date?
    public var devices: [Device]
    public var id: String
    public var image: String?
    public var invisible: Bool
    public var language: String
    public var lastActive: Date?
    public var latestHiddenChannels: [String]?
    public var mutes: [UserMuteResponse?]
    public var name: String?
    public var online: Bool
    public var privacySettings: PrivacySettingsResponse?
    public var pushNotifications: PushNotificationSettingsResponse?
    public var revokeTokensIssuedBefore: Date?
    public var role: String
    public var teams: [String]
    public var totalUnreadCount: Int
    public var unreadChannels: Int
    public var unreadThreads: Int
    public var updatedAt: Date

    public init(
        banned: Bool,
        blockedUserIds: [String]? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        devices: [Device],
        id: String,
        image: String? = nil,
        invisible: Bool,
        language: String,
        lastActive: Date? = nil,
        latestHiddenChannels: [String]? = nil,
        mutes: [UserMuteResponse?],
        name: String? = nil,
        online: Bool,
        privacySettings: PrivacySettingsResponse? = nil,
        pushNotifications: PushNotificationSettingsResponse? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        totalUnreadCount: Int,
        unreadChannels: Int,
        unreadThreads: Int,
        updatedAt: Date
    ) {
        self.banned = banned
        self.blockedUserIds = blockedUserIds
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
        case blockedUserIds = "blocked_user_ids"
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
}
