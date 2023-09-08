//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

enum StatsReporter {
    
    static func createStatsReport(
        from reports: [RTCStatisticsReport?],
        datacenter: String
    ) -> CallStatsReport {
        CallStatsReport(
            datacenter: datacenter,
            publisherStats: publisherStats(from: reports),
            publisherRawStats: reports[0], //TODO: safer
            subscriberStats: subscriberStats(from: reports),
            subscriberRawStats: reports[1], //TODO: safer
            timestamp: 0 //TODO: this
        )
    }
    
    private static func publisherStats(
        from reports: [RTCStatisticsReport?]
    ) -> AggregatedStatsReport {
        //TODO: implement
        AggregatedStatsReport(
            totalBytesSent: 0,
            totalBytesReceived: 0,
            averageJitterInMs: 0,
            averageRoundTripTimeInMs: 0,
            qualityLimitationReasons: "",
            highestFrameWidth: 0,
            highestFrameHeight: 0,
            highestFramesPerSecond: 0,
            timestamp: 0
        )
    }
    
    private static func subscriberStats(
        from reports: [RTCStatisticsReport?]
    ) -> AggregatedStatsReport {
        //TODO: implement
        AggregatedStatsReport(
            totalBytesSent: 0,
            totalBytesReceived: 0,
            averageJitterInMs: 0,
            averageRoundTripTimeInMs: 0,
            qualityLimitationReasons: "",
            highestFrameWidth: 0,
            highestFrameHeight: 0,
            highestFramesPerSecond: 0,
            timestamp: 0
        )
    }
    
}
