//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

extension CallStatsReport {
    static func dummy(
        datacenter: String = "default-datacenter",
        publisherStats: AggregatedStatsReport = .dummy(),
        publisherRawStats: RTCStatisticsReport? = nil,
        publisherBaseStats: [BaseStats] = [],
        subscriberStats: AggregatedStatsReport = .dummy(),
        subscriberRawStats: RTCStatisticsReport? = nil,
        participantsStats: ParticipantsStats = .dummy(),
        timestamp: Double = 0.0,
        trackToKindMap: [String: TrackType] = [:]
    ) -> CallStatsReport {
        CallStatsReport(
            datacenter: datacenter,
            publisherStats: publisherStats,
            publisherRawStats: publisherRawStats,
            publisherBaseStats: publisherBaseStats,
            subscriberStats: subscriberStats,
            subscriberRawStats: subscriberRawStats,
            participantsStats: participantsStats,
            timestamp: timestamp,
            trackToKindMap: trackToKindMap
        )
    }
}
