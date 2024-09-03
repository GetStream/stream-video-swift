//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]? = nil
    public var emojiCode: String? = nil
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
}
