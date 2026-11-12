//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SendReactionRequest: Sendable, Encodable, JSONEncodable {
    public let custom: [String: RawJSON]?
    public let emojiCode: String?
    public let type: String

    public init(custom: [String: RawJSON]? = nil, emojiCode: String? = nil, type: String) {
        self.custom = custom
        self.emojiCode = emojiCode
        self.type = type
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
