//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct MutableRTCStatisticsReport: Codable, Equatable {
    /// The timestamp of the report in microseconds since 1970-01-01T00:00:00Z.
    var timestamp: TimeInterval

    /// Mutable statistics objects by id.
    var statistics: [String: MutableRTCStatistics]

    /// Initialize from Objective-C RTCStatisticsReport.
    init(_ source: RTCStatisticsReport) {
        timestamp = source.timestamp_us / 1000
        var stats = [String: MutableRTCStatistics]()
        source.statistics.forEach { stats[$0.key] = $0.value.mutable }
        statistics = stats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)

        var statistics = [String: MutableRTCStatistics]()
        for key in container.allKeys {
            if key.stringValue != CodingKeys.timestamp.stringValue {
                let stat = try container.decode(MutableRTCStatistics.self, forKey: key)
                statistics[key.stringValue] = stat
            }
        }
        self.statistics = statistics
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)

        for (key, stat) in statistics {
            let dynamicKey = CodingKeys(stringValue: key)!
            try container.encode(stat, forKey: dynamicKey)
        }
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }

        static let timestamp = CodingKeys(stringValue: "timestamp")!
    }
}

extension RTCStatisticsReport {
    var mutable: MutableRTCStatisticsReport {
        .init(self)
    }
}
