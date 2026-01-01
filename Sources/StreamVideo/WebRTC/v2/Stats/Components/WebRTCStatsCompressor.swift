//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Compresses WebRTC statistics reports by removing unchanged entries.
///
/// This struct helps reduce payload size by only retaining updated
/// statistics since the last report. Timestamps are normalized for consistency.
struct WebRTCStatsCompressor {

    private var lastReport: CallStatsReport?

    /// Compresses the provided call stats report against the previous one.
    ///
    /// - Parameter report: The current call statistics report.
    /// - Returns: A tuple containing compressed publisher and subscriber stats.
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

    /// Computes the diff between old and new stats reports.
    ///
    /// Filters out unchanged statistics and resets the most recent timestamp(s).
    ///
    /// - Parameters:
    ///   - oldStats: The previous statistics report to compare.
    ///   - newStats: The current statistics report to compress.
    /// - Returns: A mutable statistics report with only changed entries,
    ///   or nil if no changes are found.
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
