//
// ReactionResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct ReactionResponse: Codable, JSONEncodable, Hashable {
    public var custom: [String: RawJSON]?
    public var emojiCode: String?
    public var type: String
    public var user: UserResponse

    public init(custom: [String: RawJSON]? = nil, emojiCode: String? = nil, type: String, user: UserResponse) {
        self.custom = custom
        self.emojiCode = emojiCode
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case emojiCode = "emoji_code"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(emojiCode, forKey: .emojiCode)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

