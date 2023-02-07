//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallUpdated: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse?
    internal var capabilitiesByRole: [String: [String]]?
    internal var createdAt: Date?
    internal var type: String

    internal init(call: CallResponse? = nil, capabilitiesByRole: [String: [String]]? = nil, createdAt: Date? = nil, type: String) {
        self.call = call
        self.capabilitiesByRole = capabilitiesByRole
        self.createdAt = createdAt
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case capabilitiesByRole = "capabilities_by_role"
        case createdAt = "created_at"
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(call, forKey: .call)
        try container.encodeIfPresent(capabilitiesByRole, forKey: .capabilitiesByRole)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
    }
}
