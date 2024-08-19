//
// UpdatedCallPermissionsEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent to notify about permission changes for a user, clients receiving this event should update their UI accordingly */

public struct UpdatedCallPermissionsEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /** The capabilities of the current user */
    public var ownCapabilities: [OwnCapability]
    /** The type of event: \"call.permissions_updated\" in this case */
    public var type: String = "call.permissions_updated"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, ownCapabilities: [OwnCapability], type: String = "call.permissions_updated", user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case ownCapabilities = "own_capabilities"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

