//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallPermissionRequest: Codable, JSONEncodable, Hashable {

    internal var callCid: String
    internal var createdAt: Date
    /** The list of permissions requested by the user */
    internal var permissions: [String]
    internal var type: String
    internal var user: UserResponse

    internal init(callCid: String, createdAt: Date, permissions: [String], type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.permissions = permissions
        self.type = type
        self.user = user
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case permissions
        case type
        case user
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}
