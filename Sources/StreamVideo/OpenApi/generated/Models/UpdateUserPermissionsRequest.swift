//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct UpdateUserPermissionsRequest: Codable, JSONEncodable, Hashable {

    internal var grantPermissions: [String]?
    internal var revokePermissions: [String]?
    internal var userId: String

    internal init(grantPermissions: [String]? = nil, revokePermissions: [String]? = nil, userId: String) {
        self.grantPermissions = grantPermissions
        self.revokePermissions = revokePermissions
        self.userId = userId
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case grantPermissions = "grant_permissions"
        case revokePermissions = "revoke_permissions"
        case userId = "user_id"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(grantPermissions, forKey: .grantPermissions)
        try container.encodeIfPresent(revokePermissions, forKey: .revokePermissions)
        try container.encode(userId, forKey: .userId)
    }
}
