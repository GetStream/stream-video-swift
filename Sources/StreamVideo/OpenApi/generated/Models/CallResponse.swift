//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** Represents a call */
internal struct CallResponse: Codable, JSONEncodable, Hashable {

    internal var broadcastEgress: String
    /** The unique identifier for a call (<type>:<id>) */
    internal var cid: String
    /** Date/time of creation */
    internal var createdAt: Date
    internal var createdBy: UserResponse
    /** Custom data for this object */
    internal var custom: [String: AnyCodable]
    internal var endedAt: Date?
    /** Call ID */
    internal var id: String
    /** The capabilities of the current user */
    internal var ownCapabilities: [String]
    internal var recordEgress: String
    internal var settings: CallSettingsResponse
    internal var team: String
    /** The type of call */
    internal var type: String
    /** Date/time of the last update */
    internal var updatedAt: Date

    internal init(
        broadcastEgress: String,
        cid: String,
        createdAt: Date,
        createdBy: UserResponse,
        custom: [String: AnyCodable],
        endedAt: Date? = nil,
        id: String,
        ownCapabilities: [String],
        recordEgress: String,
        settings: CallSettingsResponse,
        team: String,
        type: String,
        updatedAt: Date
    ) {
        self.broadcastEgress = broadcastEgress
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.endedAt = endedAt
        self.id = id
        self.ownCapabilities = ownCapabilities
        self.recordEgress = recordEgress
        self.settings = settings
        self.team = team
        self.type = type
        self.updatedAt = updatedAt
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcastEgress = "broadcast_egress"
        case cid
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case endedAt = "ended_at"
        case id
        case ownCapabilities = "own_capabilities"
        case recordEgress = "record_egress"
        case settings
        case team
        case type
        case updatedAt = "updated_at"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(broadcastEgress, forKey: .broadcastEgress)
        try container.encode(cid, forKey: .cid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encode(id, forKey: .id)
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(recordEgress, forKey: .recordEgress)
        try container.encode(settings, forKey: .settings)
        try container.encode(team, forKey: .team)
        try container.encode(type, forKey: .type)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
