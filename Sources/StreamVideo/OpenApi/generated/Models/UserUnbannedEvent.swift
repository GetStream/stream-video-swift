//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class UserUnbannedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var shadow: Bool
    public var team: String?
    public var type: String
    public var user: UserObject?

    public init(
        channelId: String,
        channelType: String,
        cid: String,
        createdAt: Date,
        shadow: Bool,
        team: String? = nil,
        type: String,
        user: UserObject? = nil
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.shadow = shadow
        self.team = team
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case shadow
        case team
        case type
        case user
    }
    
    public static func == (lhs: UserUnbannedEvent, rhs: UserUnbannedEvent) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.shadow == rhs.shadow &&
            lhs.team == rhs.team &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(shadow)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(user)
    }
}
