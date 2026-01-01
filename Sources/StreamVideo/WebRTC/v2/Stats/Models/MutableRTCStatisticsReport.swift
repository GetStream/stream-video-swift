//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A mutable and codable representation of an RTC statistics report.
///
/// This structure is used to convert the Objective-C `RTCStatisticsReport`
/// into a Swift-native format that supports mutability and encoding/decoding.
/// It holds all the individual mutable statistics entries keyed by their id,
/// as well as a timestamp representing the time at which the report was taken.
struct MutableRTCStatisticsReport: Codable, Equatable {
    /// The timestamp of the report in microseconds since 1970-01-01T00:00:00Z.
    var timestamp: TimeInterval

    /// A dictionary containing the mutable statistics, keyed by their id.
    var statistics: [String: MutableRTCStatistics]

    /// Initializes a new `MutableRTCStatisticsReport` from an
    /// Objective-C `RTCStatisticsReport`.
    ///
    /// - Parameter source: The original RTC statistics report.
    init(_ source: RTCStatisticsReport) {
        // Convert the timestamp from microseconds to milliseconds.
        timestamp = source.timestamp_us / 1000
        var stats = [String: MutableRTCStatistics]()
        // Convert each entry in the statistics to its mutable form.
        source.statistics.forEach { stats[$0.key] = $0.value.mutable }
        statistics = stats
    }

    init(
        timestamp: TimeInterval,
        statistics: [String: MutableRTCStatistics]
    ) {
        self.timestamp = timestamp
        self.statistics = statistics
    }

    /// Initializes a new instance by decoding from the given decoder.
    ///
    /// This implementation supports dynamic keys, where all keys except
    /// "timestamp" are considered as individual statistics.
    ///
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode the timestamp from the container.
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)

        var statistics = [String: MutableRTCStatistics]()
        // Decode all other keys as MutableRTCStatistics.
        for key in container.allKeys {
            if key.stringValue != CodingKeys.timestamp.stringValue {
                let stat = try container.decode(MutableRTCStatistics.self, forKey: key)
                statistics[key.stringValue] = stat
            }
        }
        self.statistics = statistics
    }

    /// Encodes this value into the given encoder.
    ///
    /// Encodes the timestamp, then encodes each statistic using its id as the key.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode the timestamp.
        try container.encode(timestamp, forKey: .timestamp)

        // Encode each statistic using a dynamic key.
        for (key, stat) in statistics {
            let dynamicKey = CodingKeys(stringValue: key)!
            try container.encode(stat, forKey: dynamicKey)
        }
    }

    /// Coding keys for encoding and decoding.
    ///
    /// Uses dynamic string keys to allow encoding arbitrary statistics,
    /// in addition to the fixed "timestamp" key.
    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }

        /// The key for the timestamp field.
        static let timestamp = CodingKeys(stringValue: "timestamp")!
    }
}

extension RTCStatisticsReport {
    /// Returns a mutable representation of the current `RTCStatisticsReport`.
    var mutable: MutableRTCStatisticsReport {
        .init(self)
    }
}
