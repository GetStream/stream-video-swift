//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var calls: [CallStateResponseFields]
    /// Duration of the request in milliseconds
    public var duration: String
    public var next: String?
    public var prev: String?

    public init(calls: [CallStateResponseFields], duration: String, next: String? = nil, prev: String? = nil) {
        self.calls = calls
        self.duration = duration
        self.next = next
        self.prev = prev
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.calls = try container.decode([CallStateResponseFields].self, forKey: .calls)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(calls, forKey: .calls)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
    }
}

extension QueryCallsResponse: Hashable {
    public static func == (lhs: QueryCallsResponse, rhs: QueryCallsResponse) -> Bool {
        lhs.calls == rhs.calls &&
            lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(calls)
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
