//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A statistics report representing WebRTC internal data, such as track or
/// codec reports, with associated timestamp and key-value details.
///
/// This structure is designed for use within the statistics pipeline,
/// allowing conversion from Objective-C WebRTC statistics to a Swift-native,
/// Codable representation for further encoding, storage, or analysis.
struct MutableRTCStatistics: Codable, Equatable {
    /// The timestamp for the statistics, in milliseconds since epoch.
    var timestamp: TimeInterval

    /// The type of the statistics (e.g., "inbound-rtp", "outbound-rtp").
    var type: String

    /// The dictionary of values reported in this statistics entry.
    ///
    /// The keys are property names; the values are raw JSON representations
    /// supporting arbitrary data types (numbers, strings, objects, etc).
    var values: [String: RawJSON]

    /// Initializes a new instance from an Objective-C `RTCStatistics` object.
    ///
    /// - Parameter source: The RTCStatistics object to convert.
    init(_ source: RTCStatistics) {
        // Convert timestamp from microseconds to milliseconds.
        timestamp = source.timestamp_us / 1000
        type = source.type
        var values = [String: RawJSON]()
        source
            .values
            .forEach { values[$0.key] = .init($0.value) }
        self.values = values
    }

    init(
        timestamp: TimeInterval,
        type: String,
        values: [String: RawJSON]
    ) {
        self.timestamp = timestamp
        self.type = type
        self.values = values
    }

    /// Decodes from a keyed container, mapping all keys except "timestamp" and
    /// "type" into the `values` dictionary.
    ///
    /// - Parameter decoder: The decoder to read data from.
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

    /// Encodes all properties and dynamic keys for values.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)

        for (key, value) in values {
            let dynamicKey = CodingKeys(stringValue: key)
            try container.encode(value, forKey: dynamicKey)
        }
    }

    /// Returns the value associated with a type-safe statistics key.
    ///
    /// This method extracts the value for the given `TrackStatKey` from the
    /// underlying statistics dictionary and attempts to cast it to the expected
    /// generic type `T`.
    ///
    /// Example:
    /// ```
    /// let val: Int? = stats.value(for: .frameHeight)
    /// ```
    ///
    /// - Parameter key: The statistics key as a `TrackStatKey`.
    /// - Returns: The value cast to type `T` if it exists and is compatible,
    ///   otherwise `nil`.
    func value<T>(
        for key: RTCStatistics.TrackStatKey
    ) -> T? {
        values[key.rawValue]?.value()
    }

    /// Returns the value for a type-safe key, or a fallback value if not present.
    ///
    /// This method extracts and casts the value for the given `TrackStatKey` from
    /// the statistics dictionary. If the value is missing or not convertible to
    /// the requested type, the provided fallback is returned.
    ///
    /// Example:
    /// ```
    /// let fps: Int = stats.value(for: .framesPerSecond, fallback: 0)
    /// ```
    ///
    /// - Parameters:
    ///   - key: The statistics key as a `TrackStatKey`.
    ///   - fallback: The value to return if the key is missing or incompatible.
    /// - Returns: The value as type `T` or the fallback.
    func value<T>(
        for key: RTCStatistics.TrackStatKey,
        fallback: T
    ) -> T {
        values[key.rawValue]?.value(fallback: fallback) ?? fallback
    }

    /// Coding keys for static ("timestamp", "type") and dynamic (property) keys.
    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(stringValue: String) { self.stringValue = stringValue }
        init(intValue: Int) {
            stringValue = "\(intValue)"
            self.intValue = intValue
        }

        static let timestamp = CodingKeys(stringValue: "timestamp")
        static let type = CodingKeys(stringValue: "type")
    }
}

extension RTCStatistics {
    /// Provides type-safe access to the keys of statistics relevant to
    /// WebRTC track encoding and decoding.
    ///
    /// Using these keys prevents typos and allows for safer value extraction.
    enum TrackStatKey: String {
        case kind
        case codecId
        case framesSent
        case framesDecoded
        case framesPerSecond
        case frameHeight
        case frameWidth
        case mediaSourceId
        case trackIdentifier
        case totalEncodeTime
        case totalDecodeTime
        case targetBitrate
        case mimeType
        case clockRate
        case payloadType
        case sdpFmtpLine
        case unknown

        public init(stringLiteral value: String) {
            self = TrackStatKey(rawValue: value) ?? .unknown
        }
    }
}

extension RTCStatistics {
    /// Returns a Swift-native, mutable statistics object for this entry.
    var mutable: MutableRTCStatistics {
        .init(self)
    }
}
