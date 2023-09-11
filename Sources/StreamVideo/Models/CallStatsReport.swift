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
    public let participantsStats: ParticipantsStats
    public let timestamp: Double
}

public struct ParticipantsStats: Sendable {
    public let report: [String: BaseStats]
}

public struct BaseStats: Sendable {
    public let bytesSent: Int
    public let bytesReceived: Int
    public let codec: String
    public let currentRoundTripTime: Double
    public let frameWidth: Int
    public let frameHeight: Int
    public let framesPerSecond: Int
    public let jitter: Double
    public let kind: String
    public let qualityLimitationReason: String
    public let rid: String
    public let ssrc: Int
    public let isPublisher: Bool
}

public struct AggregatedStatsReport: Sendable {
    public let totalBytesSent: Int
    public let totalBytesReceived: Int
    public let averageJitterInMs: Double
    public let averageRoundTripTimeInMs: Double
    public let qualityLimitationReasons: String
    public let highestFrameWidth: Int
    public let highestFrameHeight: Int
    public let highestFramesPerSecond: Int
    public let timestamp: Double
}
