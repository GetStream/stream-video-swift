//
// JoinCallRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct JoinCallRequest: Codable, JSONEncodable, Hashable {

    static let membersLimitRule = NumericRule<Int>(minimum: nil, exclusiveMinimum: false, maximum: 100, exclusiveMaximum: false, multipleOf: nil)
    /** if true the call will be created if it doesn't exist */
    public var create: Bool?
    public var data: CallRequest?
    public var location: String
    public var membersLimit: Int?
    /** If the participant is migrating from another SFU, then this is the ID of the previous SFU */
    public var migratingFrom: String?
    public var notify: Bool?
    /** if true and the call is created, the notification will include ring=true */
    public var ring: Bool?

    public init(create: Bool? = nil, data: CallRequest? = nil, location: String, membersLimit: Int? = nil, migratingFrom: String? = nil, notify: Bool? = nil, ring: Bool? = nil) {
        self.create = create
        self.data = data
        self.location = location
        self.membersLimit = membersLimit
        self.migratingFrom = migratingFrom
        self.notify = notify
        self.ring = ring
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case create
        case data
        case location
        case membersLimit = "members_limit"
        case migratingFrom = "migrating_from"
        case notify
        case ring
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(create, forKey: .create)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(membersLimit, forKey: .membersLimit)
        try container.encodeIfPresent(migratingFrom, forKey: .migratingFrom)
        try container.encodeIfPresent(notify, forKey: .notify)
        try container.encodeIfPresent(ring, forKey: .ring)
    }
}

