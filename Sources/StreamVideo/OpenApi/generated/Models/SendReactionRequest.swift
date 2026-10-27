//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SendReactionRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var custom: [String: RawJSON]?
    public var emojiCode: String?
    public var type: String

    public init(custom: [String: RawJSON]? = nil, emojiCode: String? = nil, type: String) {
        self.custom = custom
        self.emojiCode = emojiCode
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom)
        self.emojiCode = try container.decodeIfPresent(String.self, forKey: .emojiCode)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(emojiCode, forKey: .emojiCode)
        try container.encode(type, forKey: .type)
    }
}

extension SendReactionRequest: Hashable {
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
