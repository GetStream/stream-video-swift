//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A statistics report representing WebRTC internal data, such as track or
/// codec reports, with associated timestamp and key-value details.
struct MutableRTCStatistics: Codable, Equatable {
    var timestamp: TimeInterval
    var type: String
    var values: [String: RawJSON]

    init(_ source: RTCStatistics) {
        timestamp = source.timestamp_us / 1000
        type = source.type
        var values = [String: RawJSON]()
        source
            .values
            .forEach { values[$0.key] = .init($0.value) }
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)

        var values = [String: RawJSON]()
        for key in container.allKeys {
            if key.stringValue != CodingKeys.timestamp.stringValue,
               key.stringValue != CodingKeys.type.stringValue {
                let value = try container.decode(RawJSON.self, forKey: key)
                values[key.stringValue] = value
            }
        }
        self.values = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)

        for (key, value) in values {
            let dynamicKey = CodingKeys(stringValue: key)!
            try container.encode(value, forKey: dynamicKey)
        }
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }

        static let timestamp = CodingKeys(stringValue: "timestamp")!
        static let type = CodingKeys(stringValue: "type")!
    }
}

extension RTCStatistics {
    var mutable: MutableRTCStatistics {
        .init(self)
    }
}
