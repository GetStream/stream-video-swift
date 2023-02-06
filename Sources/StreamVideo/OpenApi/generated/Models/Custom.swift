//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct Custom: Codable, JSONEncodable, Hashable {

    /** Call CID */
    internal var callCid: String?
    internal var createdAt: Date?
    internal var custom: [String: AnyCodable]?
    internal var type: String

    internal init(callCid: String? = nil, createdAt: Date? = nil, custom: [String: AnyCodable]? = nil, type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(callCid, forKey: .callCid)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(type, forKey: .type)
    }
}
