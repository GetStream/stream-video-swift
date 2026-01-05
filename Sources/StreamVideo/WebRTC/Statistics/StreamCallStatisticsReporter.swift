//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a structure responsible for compiling a comprehensive report on streaming call statistics.
struct StreamCallStatisticsReporter {

    /// Builds a unified call statistics report from publisher and subscriber statistics.
    ///
    /// - Parameters:
    ///   - publisherReport: A `StreamRTCStatisticsReport` instance containing statistics
    ///     for the publisher (outbound stream).
    ///   - subscriberReport: A `StreamRTCStatisticsReport` instance containing statistics
    ///     for the subscriber (inbound stream).
    ///   - datacenter: A string representing the datacenter where the call is hosted.
    ///   - trackToKindMap: A dictionary mapping track identifiers to their corresponding
    ///   `TrackType` (e.g., audio, video).
    /// - Returns: A `CallStatsReport` structure containing aggregated statistics, raw data, and the track kind mapping.
    func buildReport(
        publisherReport: StreamRTCStatisticsReport,
        subscriberReport: StreamRTCStatisticsReport,
        datacenter: String,
        trackToKindMap: [String: TrackType]
    ) -> CallStatsReport {
        /// Initializes a `StreamCallStatisticsBuilder` for the publisher using the provided statistics,
        /// marking the track as video and direction as outbound.
        var publisherReportBuilder = StreamCallStatisticsFormatter(
            statistics: publisherReport.statistics,
            timestamp: publisherReport.timestamp,
            trackKind: .video,
            direction: .outbound
        )

        /// Initializes a `StreamCallStatisticsBuilder` for the subscriber using the provided statistics,
        /// marking the track as video and direction as inbound.
        var subscriberReportBuilder = StreamCallStatisticsFormatter(
            statistics: subscriberReport.statistics,
            timestamp: subscriberReport.timestamp,
            trackKind: .video,
            direction: .inbound
        )

        /// Compiles the final report using aggregated statistics and raw data from both
        /// the publisher and subscriber, along with participant statistics and the report timestamp.
        return CallStatsReport(
            datacenter: URL(string: datacenter)?.host ?? datacenter,
            publisherStats: publisherReportBuilder.aggregatedReport, /// Aggregated statistics for the publisher.
            publisherRawStats: publisherReport.source, /// Raw statistics for the publisher.
            publisherBaseStats: publisherReportBuilder.baseReport,
            subscriberStats: subscriberReportBuilder.aggregatedReport, /// Aggregated statistics for the subscriber.
            subscriberRawStats: subscriberReport.source, /// Raw statistics for the subscriber.
            participantsStats: publisherReportBuilder.participantsReport + subscriberReportBuilder.participantsReport,
            /// Combined participant statistics from both publisher and subscriber.
            timestamp: publisherReportBuilder.timestamp, /// Timestamp of the publisher's report, used for the overall report.
            trackToKindMap: trackToKindMap
        )
    }
}
