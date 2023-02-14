//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallPermissionsUpdated: Codable, JSONEncodable, Hashable {

    internal var callCid: String
    internal var createdAt: Date
    /** The updated list of capabilities the user has in the call */
    internal var ownCapabilities: [String]
    internal var type: String
    internal var user: UserResponse

    internal init(callCid: String, createdAt: Date, ownCapabilities: [String], type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.type = type
        self.user = user
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case ownCapabilities = "own_capabilities"
        case type
        case user
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}
