//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

public struct CallStatsReport: Sendable {
    public let datacenter: String
    public let publisherStats: AggregatedStatsReport
    public let publisherRawStats: RTCStatisticsReport?
    public let subscriberStats: AggregatedStatsReport
    public let subscriberRawStats: RTCStatisticsReport?
    //TODO: check for participants stats report
    public let timestamp: Int
}

public struct AggregatedStatsReport: Sendable {
    public let totalBytesSent: Int
    public let totalBytesReceived: Int
    public let averageJitterInMs: Int
    public let averageRoundTripTimeInMs: Int
    public let qualityLimitationReasons: String
    public let highestFrameWidth: Int
    public let highestFrameHeight: Int
    public let highestFramesPerSecond: Int
    public let timestamp: Int
}
