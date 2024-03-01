//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A wrapper around RTCStatistics that can be used to easily access its properties.
@dynamicMemberLookup
struct StreamRTCStatistics {
    /// A structure providing a type-safe way to access values from RTCStatistics' values dictionary.
    @objcMembers final class CodingKeys: NSObject {
        var trackIdentifier: String = ""
        var codecId: String = ""
        var mimeType: String = ""
        var bytesSent: Int = 0
        var bytesReceived: Int = 0
        var jitter: Double = 0
        var currentRoundTripTime: Double = 0
        var qualityLimitationReason: String = ""
        var frameWidth: Int = 0
        var frameHeight: Int = 0
        var framesPerSecond: Int = 0
        var transportId: String = ""
        var dtlsState: String = ""
        var selectedCandidatePairId: String = ""
        var kind: String = ""
        var rid: String = ""
        var ssrc: Int = 0
    }

    private let source: StreamStatisticsProtocol?

    /// The  of the `source` or empty.
    var type: String { source?.type ?? "" }

    /// The id of the `source` or empty.
    var id: String { source?.id ?? "" }

    init?(_ source: StreamStatisticsProtocol?) {
        guard let source else { return nil }
        self.source = source
    }

    /// A handy way to access values from the source's `values` storage.
    subscript<T>(dynamicMember keyPath: KeyPath<CodingKeys, T>) -> T? {
        /// Implement logic to dynamically access the members of RTCStatisticsReport
        let value = NSExpression(forKeyPath: keyPath).keyPath
        return source?.values[value] as? T
    }
}

/// A wrapper around RTCStatisticsReport that can be used to easily access its properties.
struct StreamRTCStatisticsReport {
    var statistics: [StreamRTCStatistics]
    var timestamp: TimeInterval
    var source: RTCStatisticsReport?

    init(_ source: RTCStatisticsReport?) {
        self.init(
            statistics: source?.statistics.compactMap { StreamRTCStatistics($0.value) } ?? [],
            timestamp: source?.timestamp_us ?? Date().timeIntervalSince1970,
            source: source
        )
    }

    init(
        statistics: [StreamRTCStatistics],
        timestamp: TimeInterval,
        source: RTCStatisticsReport?
    ) {
        self.statistics = statistics
        self.timestamp = timestamp
        self.source = source
    }
}

/// Describes and object that can be queried to get information about a RTCStatistics source.
protocol StreamStatisticsProtocol {

    var type: String { get }

    var id: String { get }

    var values: [String: NSObject] { get }
}

extension RTCStatistics: StreamStatisticsProtocol {}

extension RTCStatisticsReport {
    func jsonString(for type: PeerConnectionType) -> String? {
        let statsKey = type == .publisher ? "publisherStats" : "subscriberStats"
        var updated = [String: Any]()
        for (key, value) in statistics {
            let mapped: [String: Any] = [
                "id": value.id,
                "type": value.type,
                "timestamp_us": value.timestamp_us,
                "values": value.values
            ]
            updated[key] = mapped
        }
        if let json = try? JSONSerialization.data(
            withJSONObject: [statsKey: updated],
            options: .prettyPrinted
        ) {
            return String(data: json, encoding: .utf8)
        } else {
            return nil
        }
    }
}
