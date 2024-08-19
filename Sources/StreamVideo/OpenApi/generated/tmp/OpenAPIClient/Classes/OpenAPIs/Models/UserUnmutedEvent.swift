//
// UserUnmutedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserUnmutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSClientEvent {
    public var createdAt: Date
    public var targetUser: String?
    public var targetUsers: [String]?
    public var type: String = "user.unmuted"
    public var user: UserObject?

    public init(createdAt: Date, targetUser: String? = nil, targetUsers: [String]? = nil, type: String = "user.unmuted", user: UserObject? = nil) {
        self.createdAt = createdAt
        self.targetUser = targetUser
        self.targetUsers = targetUsers
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case targetUser = "target_user"
        case targetUsers = "target_users"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(targetUser, forKey: .targetUser)
        try container.encodeIfPresent(targetUsers, forKey: .targetUsers)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

