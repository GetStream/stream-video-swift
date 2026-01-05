//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SendReactionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?
    public var emojiCode: String?
    public var type: String

    public init(custom: [String: RawJSON]? = nil, emojiCode: String? = nil, type: String) {
        self.custom = custom
        self.emojiCode = emojiCode
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case emojiCode = "emoji_code"
        case type
    }
    
    public static func == (lhs: SendReactionRequest, rhs: SendReactionRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.emojiCode == rhs.emojiCode &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(emojiCode)
        hasher.combine(type)
    }
}
