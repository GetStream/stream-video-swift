//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var banned: Bool
    public var blockedUserIds: [String]
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    public var deletedAt: Date?
    public var id: String
    public var image: String?
    public var language: String
    public var lastActive: Date?
    public var name: String?
    public var online: Bool
    public var revokeTokensIssuedBefore: Date?
    public var role: String
    public var teams: [String]
    public var updatedAt: Date

    public init(
        banned: Bool,
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        online: Bool,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        updatedAt: Date
    ) {
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.id = id
        self.image = image
        self.language = language
        self.lastActive = lastActive
        self.name = name
        self.online = online
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.teams = teams
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case blockedUserIds = "blocked_user_ids"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case id
        case image
        case language
        case lastActive = "last_active"
        case name
        case online
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case updatedAt = "updated_at"
    }
}
