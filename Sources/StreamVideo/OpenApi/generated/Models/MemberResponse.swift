//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MemberResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deletedAt: Date? = nil
    public var role: String? = nil
    public var updatedAt: Date
    public var user: UserResponse
    public var userId: String

    public init(
        createdAt: Date,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        role: String? = nil,
        updatedAt: Date,
        user: UserResponse,
        userId: String
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.role = role
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case role
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}
