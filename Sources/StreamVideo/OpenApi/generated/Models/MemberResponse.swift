//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct MemberResponse: Codable, JSONEncodable, Hashable {

    /** Date/time of creation */
    internal var createdAt: Date
    /** Custom member response data */
    internal var custom: [String: AnyCodable]?
    /** Date/time of deletion */
    internal var deletedAt: Date?
    internal var duration: String?
    internal var role: String?
    /** Date/time of the last update */
    internal var updatedAt: Date
    internal var user: UserResponse
    /** User ID */
    internal var userId: String?

    internal init(
        createdAt: Date,
        custom: [String: AnyCodable]? = nil,
        deletedAt: Date? = nil,
        duration: String? = nil,
        role: String? = nil,
        updatedAt: Date,
        user: UserResponse,
        userId: String? = nil
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.duration = duration
        self.role = role
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case duration
        case role
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(user, forKey: .user)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}
