//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct JoinCallRequest: Codable, JSONEncodable, Hashable {

    internal var connectionId: String?
    internal var data: CallRequest?
    internal var datacenterHintedId: String?
    internal var members: PaginationParamsRequest?
    internal var ring: Bool?

    internal init(
        connectionId: String? = nil,
        data: CallRequest? = nil,
        datacenterHintedId: String? = nil,
        members: PaginationParamsRequest? = nil,
        ring: Bool? = nil
    ) {
        self.connectionId = connectionId
        self.data = data
        self.datacenterHintedId = datacenterHintedId
        self.members = members
        self.ring = ring
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case data
        case datacenterHintedId = "datacenter_hinted_id"
        case members
        case ring
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(connectionId, forKey: .connectionId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(datacenterHintedId, forKey: .datacenterHintedId)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(ring, forKey: .ring)
    }
}
