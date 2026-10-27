//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Send a call event to the other user
public final class SendEventRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var custom: [String: RawJSON]?

    public init(custom: [String: RawJSON]? = nil) {
        self.custom = custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
    }
}

extension SendEventRequest: Hashable {
    public static func == (lhs: SendEventRequest, rhs: SendEventRequest) -> Bool {
        lhs.custom == rhs.custom
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
    }
}
