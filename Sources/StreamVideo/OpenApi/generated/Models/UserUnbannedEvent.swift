//
// UserUnbannedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserUnbannedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var shadow: Bool
    public var team: String?
    public var type: String = "user.unbanned"
    public var user: UserObject?

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, shadow: Bool, team: String? = nil, type: String = "user.unbanned", user: UserObject? = nil) {
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channelId, forKey: .channelId)
        try container.encode(channelType, forKey: .channelType)
        try container.encode(cid, forKey: .cid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(shadow, forKey: .shadow)
        try container.encodeIfPresent(team, forKey: .team)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

