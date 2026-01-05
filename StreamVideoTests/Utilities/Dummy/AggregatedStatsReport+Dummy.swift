//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension AggregatedStatsReport {
    static func dummy(
        totalBytesSent: Int = 0,
        totalBytesReceived: Int = 0,
        averageJitterInMs: Double = 0.0,
        averageRoundTripTimeInMs: Double = 0.0,
        qualityLimitationReasons: String = "",
        highestFrameWidth: Int = 0,
        highestFrameHeight: Int = 0,
        highestFramesPerSecond: Int = 0,
        timestamp: Double = 0.0
    ) -> AggregatedStatsReport {
        AggregatedStatsReport(
            totalBytesSent: totalBytesSent,
            totalBytesReceived: totalBytesReceived,
            averageJitterInMs: averageJitterInMs,
            averageRoundTripTimeInMs: averageRoundTripTimeInMs,
            qualityLimitationReasons: qualityLimitationReasons,
            highestFrameWidth: highestFrameWidth,
            highestFrameHeight: highestFrameHeight,
            highestFramesPerSecond: highestFramesPerSecond,
            timestamp: timestamp
        )
    }
}
