//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct MemberRequest: Codable, JSONEncodable, Hashable {

    internal var custom: [String: AnyCodable]?
    internal var role: String
    internal var user: UserObjectRequest?
    internal var userId: String

    internal init(custom: [String: AnyCodable]? = nil, role: String, user: UserObjectRequest? = nil, userId: String) {
        self.custom = custom
        self.role = role
        self.user = user
        self.userId = userId
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case role
        case user
        case userId = "user_id"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encode(userId, forKey: .userId)
    }
}
