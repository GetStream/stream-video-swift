//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct WebRTCStatsCompressor {

    private var lastReport: CallStatsReport?

    mutating func compress(_ report: CallStatsReport) -> (
        publisher: MutableRTCStatisticsReport?,
        subscriber: MutableRTCStatisticsReport?
    ) {
        let publisherRawStats: MutableRTCStatisticsReport? = {
            if let value = report.publisherRawStats {
                return execute(
                    oldStats: lastReport?.publisherRawStats,
                    newStats: value
                )
            } else {
                return nil
            }
        }()

        let subscriberRawStats: MutableRTCStatisticsReport? = {
            if let value = report.subscriberRawStats {
                return execute(
                    oldStats: lastReport?.subscriberRawStats,
                    newStats: value
                )
            } else {
                return nil
            }
        }()
        
        lastReport = report
        return (publisherRawStats, subscriberRawStats)
    }
    
    private func execute(
        oldStats: RTCStatisticsReport?,
        newStats: RTCStatisticsReport
    ) -> MutableRTCStatisticsReport? {
        var newReport = newStats.mutable

        guard let oldReport = oldStats?.mutable else { return newReport }

        // Filter out keys that haven't changed
        newReport.statistics = newReport
            .statistics
            .filter { $0.value != oldReport.statistics[$0.key] }

        guard !newReport.statistics.isEmpty else {
            return nil
        }

        // Extract maxTimestamp
        let maxTimestamp: Double = newReport.statistics.values.reduce(0) { partialResult, statistics in
            partialResult <= statistics.timestamp ? statistics.timestamp : partialResult
        }

        // Set timestamp to 0 for reports with max timestamp
        newReport
            .statistics
            .filter { $0.value.timestamp == maxTimestamp }
            .forEach {
                var entry = $0.value
                entry.timestamp = 0
                newReport.statistics[$0.key] = entry
            }
        
        // Set overall timestamp
        newReport.timestamp = maxTimestamp

        return newReport
    }
}
