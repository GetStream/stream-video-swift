//
// Ban.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct Ban: Codable, JSONEncodable, Hashable {
    public var channel: Channel?
    public var createdAt: Date
    public var createdBy: UserObject?
    public var expires: Date?
    public var reason: String?
    public var shadow: Bool
    public var target: UserObject?

    public init(channel: Channel? = nil, createdAt: Date, createdBy: UserObject? = nil, expires: Date? = nil, reason: String? = nil, shadow: Bool, target: UserObject? = nil) {
        self.channel = channel
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.expires = expires
        self.reason = reason
        self.shadow = shadow
        self.target = target
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case createdBy = "created_by"
        case expires
        case reason
        case shadow
        case target
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(channel, forKey: .channel)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(expires, forKey: .expires)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encode(shadow, forKey: .shadow)
        try container.encodeIfPresent(target, forKey: .target)
    }
}

