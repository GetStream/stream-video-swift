//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallPermissionsUpdated: Codable, JSONEncodable, Hashable {

    /** Call CID */
    internal var callCid: String?
    internal var createdAt: Date?
    internal var ownCapabilities: [String]?
    internal var type: String

    internal init(callCid: String? = nil, createdAt: Date? = nil, ownCapabilities: [String]? = nil, type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case ownCapabilities = "own_capabilities"
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(callCid, forKey: .callCid)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(type, forKey: .type)
    }
}
