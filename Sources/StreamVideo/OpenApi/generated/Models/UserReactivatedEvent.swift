//
// UserReactivatedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserReactivatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    public var createdAt: Date
    public var type: String = "user.reactivated"
    public var user: UserObject?

    public init(createdAt: Date, type: String = "user.reactivated", user: UserObject? = nil) {
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

