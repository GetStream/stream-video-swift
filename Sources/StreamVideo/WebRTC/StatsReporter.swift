//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

enum StatsReporter {
    
    static func createStatsReport(
        from reports: [RTCStatisticsReport?],
        datacenter: String
    ) -> CallStatsReport {
        let participantsStats = participantsStats(from: reports)
        let timestamp = reports.first??.timestamp_us ?? 0
        let publisherReport: RTCStatisticsReport? = reports[safe: 0] ?? nil
        let subscriberReport: RTCStatisticsReport? = reports[safe: 1] ?? nil
        return CallStatsReport(
            datacenter: datacenter,
            publisherStats: publisherStats(from: participantsStats, timestamp: timestamp),
            publisherRawStats: publisherReport,
            subscriberStats: subscriberStats(from: participantsStats, timestamp: timestamp),
            subscriberRawStats: subscriberReport,
            participantsStats: participantsStats,
            timestamp: timestamp
        )
    }
    
    static func participantsStats(
        from reports: [RTCStatisticsReport?]
    ) -> ParticipantsStats {
        guard reports.count >= 2 else {
            return ParticipantsStats(report: [:])
        }
        var participants = [String: BaseStats]()
        for (index, report) in reports.enumerated() {
            let values = report?.statistics
            var current = [String: [String: Any]]()
            var fallbackCodecId: String?
            if let values {
                for (_, value) in values {
                    let stats = value.values
                    if let trackIdentifier = stats[StatsConstants.trackIdentifier] as? String,
                        stats[StatsConstants.kind] as? String == "video" {
                        if var existing = current[trackIdentifier] {
                            for (key, value) in stats {
                                existing[key] = value
                            }
                            current[trackIdentifier] = existing
                        } else {
                            current[trackIdentifier] = stats
                        }
                    }
                    if let codecId = stats[StatsConstants.codecId] as? String,
                        stats[StatsConstants.kind] as? String == "video" {
                        fallbackCodecId = codecId
                    }
                }
            }
            for (key, stats) in current {
                let codecId = stats[StatsConstants.codecId] as? String ?? fallbackCodecId ?? ""
                let codecInfo = values?[codecId] as? RTCStatistics
                let codec = codecInfo?.values[StatsConstants.mimeType] as? String ?? ""
                let baseStats = makeBaseStats(from: stats, codec: codec, index: index)
                participants[key] = baseStats
            }
        }
        
        return ParticipantsStats(report: participants)
    }
    
    static func makeBaseStats(
        from stats: [String: Any],
        codec: String,
        index: Int
    ) -> BaseStats {
        let baseStats = BaseStats(
            bytesSent: stats[StatsConstants.bytesSent] as? Int ?? 0,
            bytesReceived: stats[StatsConstants.bytesReceived] as? Int ?? 0,
            codec: codec,
            currentRoundTripTime: stats[StatsConstants.currentRoundTripTime] as? Double ?? 0,
            frameWidth: stats[StatsConstants.frameWidth] as? Int ?? 0,
            frameHeight: stats[StatsConstants.frameHeight] as? Int ?? 0,
            framesPerSecond: stats[StatsConstants.framesPerSecond] as? Int ?? 0,
            jitter: stats[StatsConstants.jitter] as? Double ?? 0,
            kind: stats[StatsConstants.kind] as? String ?? "video",
            qualityLimitationReason: stats[StatsConstants.qualityLimitationReason] as? String ?? "",
            rid: stats[StatsConstants.rid] as? String ?? "",
            ssrc: stats[StatsConstants.ssrc] as? Int ?? 0,
            isPublisher: index == 0
        )
        
        return baseStats
    }
    
    static func publisherStats(
        from stats: ParticipantsStats,
        timestamp: Double
    ) -> AggregatedStatsReport {
        let filteredStats = stats.report.values.filter { $0.isPublisher }
        return aggregatedReport(from: filteredStats, timestamp: timestamp)
    }
    
    static func subscriberStats(
        from stats: ParticipantsStats,
        timestamp: Double
    ) -> AggregatedStatsReport {
        let filteredStats = stats.report.values.filter { $0.isPublisher == false }
        return aggregatedReport(from: filteredStats, timestamp: timestamp)
    }
    
    static func aggregatedReport(
        from stats: [BaseStats],
        timestamp: Double
    ) -> AggregatedStatsReport {
        var totalBytesSent = 0
        var totalBytesReceived = 0
        var totalJitter: Double = 0
        var totalRoundTripTime: Double = 0
        var highestFrameWidth = 0
        var highestFrameHeight = 0
        var highestFps = 0
        var qualityReasons = ""
        for stat in stats {
            totalBytesSent += stat.bytesSent
            totalBytesReceived += stat.bytesReceived
            totalJitter += stat.jitter
            totalRoundTripTime += stat.currentRoundTripTime
            highestFrameWidth = max(stat.frameWidth, highestFrameWidth)
            highestFrameHeight = max(stat.frameHeight, highestFrameHeight)
            highestFps = max(stat.framesPerSecond, highestFps)
            if !stat.qualityLimitationReason.isEmpty {
                qualityReasons += "\(stat.qualityLimitationReason)|"
            }
        }
        let totalEntries = Double(stats.count)
        let averageJitter = totalJitter / totalEntries
        let averageRoundTripTime = totalRoundTripTime / totalEntries
        return AggregatedStatsReport(
            totalBytesSent: totalBytesSent,
            totalBytesReceived: totalBytesReceived,
            averageJitterInMs: averageJitter,
            averageRoundTripTimeInMs: averageRoundTripTime,
            qualityLimitationReasons: qualityReasons,
            highestFrameWidth: highestFrameWidth,
            highestFrameHeight: highestFrameHeight,
            highestFramesPerSecond: highestFps,
            timestamp: timestamp
        )
    }
}

enum StatsConstants {
    static let trackIdentifier = "trackIdentifier"
    static let bytesSent = "bytesSent"
    static let bytesReceived = "bytesReceived"
    static let codecId = "codecId"
    static let currentRoundTripTime = "currentRoundTripTime"
    static let frameWidth = "frameWidth"
    static let frameHeight = "frameHeight"
    static let framesPerSecond = "framesPerSecond"
    static let jitter = "jitter"
    static let kind = "kind"
    static let qualityLimitationReason = "qualityLimitationReason"
    static let rid = "rid"
    static let ssrc = "ssrc"
    static let mimeType = "mimeType"
}
