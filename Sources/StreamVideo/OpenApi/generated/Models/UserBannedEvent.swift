//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserBannedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var createdBy: UserObject
    public var expiration: Date?
    public var reason: String?
    public var shadow: Bool
    public var team: String?
    public var type: String
    public var user: UserObject?

    public init(
        channelId: String,
        channelType: String,
        cid: String,
        createdAt: Date,
        createdBy: UserObject,
        expiration: Date? = nil,
        reason: String? = nil,
        shadow: Bool,
        team: String? = nil,
        type: String,
        user: UserObject? = nil
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.expiration = expiration
        self.reason = reason
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
        case createdBy = "created_by"
        case expiration
        case reason
        case shadow
        case team
        case type
        case user
    }
}
