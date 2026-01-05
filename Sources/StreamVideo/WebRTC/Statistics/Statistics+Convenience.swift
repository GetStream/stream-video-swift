//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A wrapper around RTCStatistics that can be used to easily access its properties.
@dynamicMemberLookup
struct StreamRTCStatistics {
    /// A structure providing a type-safe way to access values from RTCStatistics' values dictionary.
    @objcMembers final class CodingKeys: NSObject, @unchecked Sendable {
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
    
    var timestamp_us: CFTimeInterval { get }

    var values: [String: NSObject] { get }
}

protocol StreamStatisticsReportProtocol {
    
    var jsonString: String? { get }
    
    var stats: [String: any StreamStatisticsProtocol] { get }
}

extension RTCStatistics: StreamStatisticsProtocol {}
extension RTCStatisticsReport: StreamStatisticsReportProtocol {
    var stats: [String: any StreamStatisticsProtocol] {
        self.statistics
    }
}

extension StreamStatisticsReportProtocol {
    var jsonString: String? {
        var statsArray = [Any]()
        for (_, value) in stats {
            var entry: [String: Any] = ["type": value.type, "timestamp": value.timestamp_us, "id": value.id]
            for (key, value) in value.values {
                entry[key] = value
            }
            statsArray.append(entry)
        }
        if let json = try? JSONSerialization.data(
            withJSONObject: statsArray,
            options: .prettyPrinted
        ) {
            return String(data: json, encoding: .utf8)
        } else {
            return nil
        }
    }
}
