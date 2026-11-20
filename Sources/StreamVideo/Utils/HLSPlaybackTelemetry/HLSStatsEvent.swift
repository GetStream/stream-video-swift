//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A player event carried beside a report. `started`, `stats`, and `ended`
/// are report types, so they are not valid event types.
final class HLSStatsEvent: Encodable, Sendable {
    let type: String
    let timestamp: Int64
    let data: [String: String]

    init(type: String, timestamp: Int64, data: [String: String]) {
        self.type = type
        self.timestamp = timestamp
        self.data = data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        if !data.isEmpty {
            try container.encode(data, forKey: .data)
        }
    }
}
