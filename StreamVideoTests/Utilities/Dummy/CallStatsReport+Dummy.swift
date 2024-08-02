//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

extension CallStatsReport {
    static func dummy(
        datacenter: String = "default-datacenter",
        publisherStats: AggregatedStatsReport = .dummy(),
        publisherRawStats: RTCStatisticsReport? = nil,
        subscriberStats: AggregatedStatsReport = .dummy(),
        subscriberRawStats: RTCStatisticsReport? = nil,
        participantsStats: ParticipantsStats = .dummy(),
        timestamp: Double = 0.0
    ) -> CallStatsReport {
        CallStatsReport(
            datacenter: datacenter,
            publisherStats: publisherStats,
            publisherRawStats: publisherRawStats,
            subscriberStats: subscriberStats,
            subscriberRawStats: subscriberRawStats,
            participantsStats: participantsStats,
            timestamp: timestamp
        )
    }
}
