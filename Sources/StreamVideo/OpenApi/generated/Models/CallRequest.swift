//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallRequest: Codable, JSONEncodable, Hashable {

    internal var createdBy: UserRequest?
    internal var createdById: String?
    internal var custom: [String: AnyCodable]?
    internal var members: [MemberRequest]?
    internal var settingsOverride: CallSettingsRequest?
    internal var team: String?

    internal init(
        createdBy: UserRequest? = nil,
        createdById: String? = nil,
        custom: [String: AnyCodable]? = nil,
        members: [MemberRequest]? = nil,
        settingsOverride: CallSettingsRequest? = nil,
        team: String? = nil
    ) {
        self.createdBy = createdBy
        self.createdById = createdById
        self.custom = custom
        self.members = members
        self.settingsOverride = settingsOverride
        self.team = team
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdBy = "created_by"
        case createdById = "created_by_id"
        case custom
        case members
        case settingsOverride = "settings_override"
        case team
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(createdById, forKey: .createdById)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(settingsOverride, forKey: .settingsOverride)
        try container.encodeIfPresent(team, forKey: .team)
    }
}
