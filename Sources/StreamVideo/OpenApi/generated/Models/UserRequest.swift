//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct UserRequest: Codable, JSONEncodable, Hashable {

    internal var custom: [String: AnyCodable]?
    /** User ID */
    internal var id: String
    internal var image: String?
    /** Optional name of user */
    internal var name: String?
    internal var role: String
    internal var teams: [String]?

    internal init(
        custom: [String: AnyCodable]? = nil,
        id: String,
        image: String? = nil,
        name: String? = nil,
        role: String,
        teams: [String]? = nil
    ) {
        self.custom = custom
        self.id = id
        self.image = image
        self.name = name
        self.role = role
        self.teams = teams
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case image
        case name
        case role
        case teams
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(teams, forKey: .teams)
    }
}
