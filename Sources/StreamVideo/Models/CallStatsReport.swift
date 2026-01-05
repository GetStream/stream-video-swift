//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A struct representing a call stats report.
public struct CallStatsReport: Sendable {
    /// The datacenter where the call is happening.
    public let datacenter: String
    /// The aggregated publisher stats for the call.
    public let publisherStats: AggregatedStatsReport
    /// The raw publisher statistics report for the call.
    public let publisherRawStats: RTCStatisticsReport?
    public let publisherBaseStats: [BaseStats]
    /// The aggregated subscriber stats for the call.
    public let subscriberStats: AggregatedStatsReport
    /// The raw subscriber statistics report for the call.
    public let subscriberRawStats: RTCStatisticsReport?
    /// The statistics related to participants in the call.
    public let participantsStats: ParticipantsStats
    /// The timestamp when the call stats report was generated.
    public let timestamp: Double

    let trackToKindMap: [String: TrackType]
}

/// A struct representing statistics for participants in the call.
public struct ParticipantsStats: Sendable, Equatable {
    /// The report containing statistics for individual participants.
    public let report: [String: [BaseStats]]

    public static func + (
        lhs: ParticipantsStats,
        rhs: ParticipantsStats
    ) -> ParticipantsStats {
        ParticipantsStats(report: lhs.report.merging(rhs.report) { $1 })
    }
}

/// A struct representing basic statistics for a participant in the call.
public struct BaseStats: Sendable, Equatable {
    /// The total bytes sent by the participant.
    public let bytesSent: Int
    /// The total bytes received by the participant.
    public let bytesReceived: Int
    /// The codec used by the participant for audio/video.
    public let codec: String
    /// The current round-trip time in milliseconds.
    public let currentRoundTripTime: Double
    /// The frame width of the video sent by the participant.
    public let frameWidth: Int
    /// The frame height of the video sent by the participant.
    public let frameHeight: Int
    /// The frames per second for the video sent by the participant.
    public let framesPerSecond: Int
    /// The jitter in the participant's video stream.
    public let jitter: Double
    /// The type of media (audio or video) sent by the participant.
    public let kind: String
    /// The reason for any quality limitations in the media.
    public let qualityLimitationReason: String
    /// The unique identifier for the media stream (if applicable).
    public let rid: String
    /// The synchronization source identifier (SSRC) for the media stream.
    public let ssrc: Int
    /// Indicates whether the participant is a publisher.
    public let isPublisher: Bool
}

/// A struct representing an aggregated stats report for the call.
public struct AggregatedStatsReport: Sendable, Equatable {
    /// The total bytes sent by all participants.
    public internal(set) var totalBytesSent: Int
    /// The total bytes received by all participants.
    public internal(set) var totalBytesReceived: Int
    /// The average jitter across all participants in milliseconds.
    public internal(set) var averageJitterInMs: Double
    /// The average round-trip time across all participants in milliseconds.
    public internal(set) var averageRoundTripTimeInMs: Double
    /// The reasons for quality limitations in the call.
    public internal(set) var qualityLimitationReasons: String
    /// The highest frame width among all video streams.
    public internal(set) var highestFrameWidth: Int
    /// The highest frame height among all video streams.
    public internal(set) var highestFrameHeight: Int
    /// The highest frames per second among all video streams.
    public internal(set) var highestFramesPerSecond: Int
    /// The timestamp when the aggregated stats report was generated.
    public internal(set) var timestamp: Double
}
