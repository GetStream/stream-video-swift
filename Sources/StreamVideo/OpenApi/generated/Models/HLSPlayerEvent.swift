//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class HLSPlayerEvent: Sendable, Encodable, JSONEncodable {
    public let data: [String: RawJSON]?
    /// Unix time in milliseconds when the event happened
    public let timestamp: Int
    /// Event type, e.g. stall_start, stall_end, quality_change, error
    public let type: String

    public init(data: [String: RawJSON]? = nil, timestamp: Int, type: String) {
        self.data = data
        self.timestamp = timestamp
        self.type = type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
    }
}

extension HLSPlayerEvent: Hashable {
    public static func == (lhs: HLSPlayerEvent, rhs: HLSPlayerEvent) -> Bool {
        lhs.data == rhs.data &&
            lhs.timestamp == rhs.timestamp &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(timestamp)
        hasher.combine(type)
    }
}
