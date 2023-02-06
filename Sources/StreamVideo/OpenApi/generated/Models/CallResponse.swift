//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** Represents a call */
internal struct CallResponse: Codable, JSONEncodable, Hashable {

    internal var broadcastEgress: String?
    /** The unique identifier for a call (<type>:<id>) */
    internal var cid: String?
    /** Date/time of creation */
    internal var createdAt: Date
    internal var createdBy: UserResponse
    internal var custom: [String: AnyCodable]?
    /** Date/time of end */
    internal var endedAt: Date?
    /** Call ID */
    internal var id: String?
    internal var ownCapabilities: [String]?
    internal var recordEgress: String?
    internal var settings: CallSettingsResponse
    internal var team: String?
    /** The type of call */
    internal var type: String?
    /** Date/time of the last update */
    internal var updatedAt: Date

    internal init(
        broadcastEgress: String? = nil,
        cid: String? = nil,
        createdAt: Date,
        createdBy: UserResponse,
        custom: [String: AnyCodable]? = nil,
        endedAt: Date? = nil,
        id: String? = nil,
        ownCapabilities: [String]? = nil,
        recordEgress: String? = nil,
        settings: CallSettingsResponse,
        team: String? = nil,
        type: String? = nil,
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
        try container.encodeIfPresent(broadcastEgress, forKey: .broadcastEgress)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(ownCapabilities, forKey: .ownCapabilities)
        try container.encodeIfPresent(recordEgress, forKey: .recordEgress)
        try container.encode(settings, forKey: .settings)
        try container.encodeIfPresent(team, forKey: .team)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
