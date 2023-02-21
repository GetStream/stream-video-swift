//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct OwnUserResponse: Codable, JSONEncodable, Hashable {

    internal var createdAt: Date
    internal var custom: [String: AnyCodable]
    internal var deletedAt: Date?
    internal var devices: [Device]
    internal var id: String
    internal var image: String?
    internal var name: String?
    internal var role: String
    internal var teams: [String]?
    internal var updatedAt: Date

    internal init(
        createdAt: Date,
        custom: [String: AnyCodable],
        deletedAt: Date? = nil,
        devices: [Device],
        id: String,
        image: String? = nil,
        name: String? = nil,
        role: String,
        teams: [String]? = nil,
        updatedAt: Date
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.devices = devices
        self.id = id
        self.image = image
        self.name = name
        self.role = role
        self.teams = teams
        self.updatedAt = updatedAt
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case devices
        case id
        case image
        case name
        case role
        case teams
        case updatedAt = "updated_at"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(devices, forKey: .devices)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(teams, forKey: .teams)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
