//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: ReactionResponse, rhs: ReactionResponse) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.emojiCode == rhs.emojiCode &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(emojiCode)
        hasher.combine(type)
        hasher.combine(user)
    }
}
