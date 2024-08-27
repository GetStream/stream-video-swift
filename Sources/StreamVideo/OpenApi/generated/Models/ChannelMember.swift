//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ChannelMember: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var banExpires: Date? = nil
    public var banned: Bool
    public var channelRole: String
    public var createdAt: Date
    public var deletedAt: Date? = nil
    public var inviteAcceptedAt: Date? = nil
    public var inviteRejectedAt: Date? = nil
    public var invited: Bool? = nil
    public var isModerator: Bool? = nil
    public var notificationsMuted: Bool
    public var shadowBanned: Bool
    public var status: String? = nil
    public var updatedAt: Date
    public var user: UserObject? = nil
    public var userId: String? = nil

    public init(
        banExpires: Date? = nil,
        banned: Bool,
        channelRole: String,
        createdAt: Date,
        deletedAt: Date? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        invited: Bool? = nil,
        isModerator: Bool? = nil,
        notificationsMuted: Bool,
        shadowBanned: Bool,
        status: String? = nil,
        updatedAt: Date,
        user: UserObject? = nil,
        userId: String? = nil
    ) {
        self.banExpires = banExpires
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.invited = invited
        self.isModerator = isModerator
        self.notificationsMuted = notificationsMuted
        self.shadowBanned = shadowBanned
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
        case invited
        case isModerator = "is_moderator"
        case notificationsMuted = "notifications_muted"
        case shadowBanned = "shadow_banned"
        case status
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}
