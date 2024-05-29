//
// UserResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserResponse: Codable, JSONEncodable, Hashable {
    public var banned: Bool
    /** Date/time of creation */
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var deactivatedAt: Date?
    /** Date/time of deletion */
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
    /** Date/time of the last update */
    public var updatedAt: Date

    public init(banned: Bool, createdAt: Date, custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, id: String, image: String? = nil, language: String, lastActive: Date? = nil, name: String? = nil, online: Bool, revokeTokensIssuedBefore: Date? = nil, role: String, teams: [String], updatedAt: Date) {
        self.banned = banned
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(banned, forKey: .banned)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deactivatedAt, forKey: .deactivatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(lastActive, forKey: .lastActive)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(online, forKey: .online)
        try container.encodeIfPresent(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encode(role, forKey: .role)
        try container.encode(teams, forKey: .teams)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

