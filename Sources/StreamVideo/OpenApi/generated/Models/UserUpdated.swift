//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct UserUpdated: Codable, JSONEncodable, Hashable {

    /** Date/time of creation */
    internal var createdAt: Date?
    /** Event Type */
    internal var type: String
    internal var user: UserObject?

    internal init(createdAt: Date? = nil, type: String, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case user
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}
