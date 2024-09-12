//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class ChannelMember: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var banExpires: Date?
    public var banned: Bool
    public var channelRole: String
    public var createdAt: Date
    public var deletedAt: Date?
    public var inviteAcceptedAt: Date?
    public var inviteRejectedAt: Date?
    public var invited: Bool?
    public var isModerator: Bool?
    public var notificationsMuted: Bool
    public var shadowBanned: Bool
    public var status: String?
    public var updatedAt: Date
    public var user: UserObject?
    public var userId: String?

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
    
    public static func == (lhs: ChannelMember, rhs: ChannelMember) -> Bool {
        lhs.banExpires == rhs.banExpires &&
            lhs.banned == rhs.banned &&
            lhs.channelRole == rhs.channelRole &&
            lhs.createdAt == rhs.createdAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.inviteAcceptedAt == rhs.inviteAcceptedAt &&
            lhs.inviteRejectedAt == rhs.inviteRejectedAt &&
            lhs.invited == rhs.invited &&
            lhs.isModerator == rhs.isModerator &&
            lhs.notificationsMuted == rhs.notificationsMuted &&
            lhs.shadowBanned == rhs.shadowBanned &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(banExpires)
        hasher.combine(banned)
        hasher.combine(channelRole)
        hasher.combine(createdAt)
        hasher.combine(deletedAt)
        hasher.combine(inviteAcceptedAt)
        hasher.combine(inviteRejectedAt)
        hasher.combine(invited)
        hasher.combine(isModerator)
        hasher.combine(notificationsMuted)
        hasher.combine(shadowBanned)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
