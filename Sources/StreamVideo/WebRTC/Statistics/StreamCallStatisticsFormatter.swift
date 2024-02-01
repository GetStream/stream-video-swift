//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a structure for constructing and aggregating streaming call statistics.
struct StreamCallStatisticsFormatter {

    /// Specifies the type of track.
    enum TrackKind: String, Equatable { case video, audio }

    /// Specifies the stream's direction.
    enum Direction: String, Equatable { case inbound = "inbound-rtp", outbound = "outbound-rtp" }

    /// Types of RTC statistics for filtering and aggregation.
    enum RTCStatisticType: String { case codec, transport, candidatePair = "candidate-pair" }

    /// Represents the DTLS state as connected.
    enum RTCTransportDtlsState: String { case connected }

    /// Holds streaming statistics.
    var statistics: [StreamRTCStatistics]

    /// Timestamp for the statistics collection.
    var timestamp: TimeInterval

    /// The kind of track (audio or video).
    var trackKind: TrackKind

    /// The direction (inbound or outbound) of the stream.
    var direction: Direction

    /// Lazy-initialized base summary of the statistics.
    lazy var baseReport: [BaseStats] = baseFormat()

    /// Lazy-initialized aggregated summary of the statistics.
    lazy var aggregatedReport: AggregatedStatsReport = aggregatedFormat()

    /// Lazy-initialized detailed report for each participant.
    lazy var participantsReport: ParticipantsStats = participantsReportFormat()

    /// Cache for codec statistics to avoid repeated computations.
    private var codecs: [String: StreamRTCStatistics] = [:]

    /// Initializes the struct with provided statistics and their attributes.
    init(
        statistics: [StreamRTCStatistics],
        timestamp: TimeInterval,
        trackKind: TrackKind,
        direction: Direction
    ) {
        self.statistics = statistics
        self.timestamp = timestamp
        self.trackKind = trackKind
        self.direction = direction
    }

    /// Formats the raw statistics into a base format for easier aggregation.
    private mutating func baseFormat() -> [BaseStats] {
        /// Filters and maps the statistics to a basic structure.
        statistics
            .filter { $0.type == direction.rawValue && $0.kind == trackKind.rawValue }
            .map { makeBase(of: $0) }
    }

    /// Builds an aggregated report from the statistics.
    private mutating func aggregatedFormat() -> AggregatedStatsReport {
        /// Directly calls the `aggregate` function on formatted statistics to produce the report.
        makeAggregated(baseReport)
    }

    /// Builds a participants report based on the collected statistics.
    private mutating func participantsReportFormat() -> ParticipantsStats {
        /// Determines if statistics pertain to outbound streams.
        let isOutbound = direction == .outbound

        /// Filters statistics for video based on the track kind and direction.
        let videoStatistics = statistics.filter { statistic in
            guard statistic.kind == trackKind.rawValue else { return false }

            /// - Note: outbound statistics do not contain the trackIdentifier.
            return isOutbound
            ? statistic.type == direction.rawValue
            : statistic.trackIdentifier != nil
        }

        /// Optionally overrides the track identifier for outbound statistics.
        ///
        /// - Note: It's used on when direction is `outbound`(publishing) where the the codec
        /// information exists in an RTCStatistics object that doesn't have the trackIdentifier. In that case
        /// we look into the rest of the statistics to find the first that contains a trackIdentifier. As this object
        /// is constrained with reports from either participants or subscribers, there is now case where
        /// we may get a subscriber's track identifier instead of publisher.
        let overrideTrackIdentifier = isOutbound ? statistics.compactMap { $0.trackIdentifier }.first : nil

        /// Aggregates statistics into a report structured by track identifiers.
        let report = videoStatistics.reduce(into: [String: [BaseStats]]()) { partialResult, videoStatistic in
            guard
                let trackIdentifier: String = videoStatistic.trackIdentifier ?? overrideTrackIdentifier
            else { return }

            let baseStats = makeBase(of: videoStatistic)
            if partialResult[trackIdentifier] == nil {
                partialResult[trackIdentifier] = []
            }
            partialResult[trackIdentifier]?.append(baseStats)
        }

        /// Returns the constructed participants statistics report.
        return ParticipantsStats(report: report)
    }

    // MARK: - Factory methods

    /// Processes a single statistic and formats it into a basic statistical structure.
    private mutating func makeBase(
        of statistic: StreamRTCStatistics
    ) -> BaseStats {
        var roundTripTime: Double = 0.0

        /// Attempts to find a related transport and candidate pair to determine round trip time.
        if let transport = statistics.first(where: { $0.type == RTCStatisticType.transport.rawValue && $0.id == statistic.transportId }),
           transport.dtlsState == RTCTransportDtlsState.connected.rawValue,
           let selectedCandidatePairId: String = transport.selectedCandidatePairId,
           let candidatePairStatistic = statistics.first(where: { $0.type == RTCStatisticType.candidatePair.rawValue && $0.id == selectedCandidatePairId }),
           let currentRoundTripTime: Double = candidatePairStatistic.currentRoundTripTime {
            roundTripTime = currentRoundTripTime
        }

        /// Determines the MIME type of the codec used for the stream.
        let mimeType = {
            guard let codecId = statistic.codecId, let codec = self.codec(for: codecId) else { return "" }
            return codec.mimeType ?? ""
        }()

        /// Returns a structured representation of the basic statistics for a stream.
        return BaseStats(
            bytesSent: statistic.bytesSent ?? 0,
            bytesReceived: statistic.bytesReceived ?? 0,
            codec: mimeType,
            currentRoundTripTime: roundTripTime,
            frameWidth: statistic.frameWidth ?? 0,
            frameHeight: statistic.frameHeight ?? 0,
            framesPerSecond: statistic.framesPerSecond ?? 0,
            jitter: statistic.jitter ?? 0,
            kind: statistic.kind ?? trackKind.rawValue,
            qualityLimitationReason: statistic.qualityLimitationReason ?? "",
            rid: statistic.rid ?? "",
            ssrc: statistic.ssrc ?? 0,
            isPublisher: direction == .outbound
        )
    }

    /// Aggregates the base statistics into a comprehensive report.
    private func makeAggregated(
        _ baseStats: [BaseStats]
    ) -> AggregatedStatsReport {
        var result = AggregatedStatsReport(
            totalBytesSent: 0,
            totalBytesReceived: 0,
            averageJitterInMs: 0,
            averageRoundTripTimeInMs: 0,
            qualityLimitationReasons: "",
            highestFrameWidth: 0,
            highestFrameHeight: 0,
            highestFramesPerSecond: 0,
            timestamp: timestamp
        )

        /// Early return if there are no statistics to aggregate.
        guard !baseStats.isEmpty else { return result }
        
        var qualityLimitationReasons: Set<String> = []
        for baseStat in baseStats {
            /// Summing up and averaging metrics across all statistics.
            result.totalBytesSent += baseStat.bytesSent
            result.totalBytesReceived += baseStat.bytesReceived
            result.averageJitterInMs += baseStat.jitter
            result.averageRoundTripTimeInMs += baseStat.currentRoundTripTime
            qualityLimitationReasons.insert(baseStat.qualityLimitationReason)
            /// Checking for the highest quality video frame dimensions and frame rate.
            let statSize = CGSize(width: baseStat.frameWidth, height: baseStat.frameHeight)
            let aggregatedSize = CGSize(width: result.highestFrameWidth, height: result.highestFrameHeight)
            if contains(size: statSize, within: aggregatedSize) {
                result.highestFrameWidth = baseStat.frameWidth
                result.highestFrameHeight = baseStat.frameHeight
                result.highestFramesPerSecond = baseStat.framesPerSecond
            }
        }

        /// Finalizing averages and compiling quality limitation reasons.
        let count = Double(baseStats.endIndex)
        if count > 0 {
            result.averageJitterInMs /= count
            result.averageRoundTripTimeInMs /= count
        }
        result.qualityLimitationReasons = qualityLimitationReasons.sorted().joined(separator: ",")

        return result
    }

    // MARK: - Private helpers

    /// Checks if one size can fully contain another. Used for comparing video frame sizes.
    private func contains(
        size containerSize: CGSize,
        within containedSize: CGSize
    ) -> Bool {
        containerSize.width >= containedSize.width && containerSize.height >= containedSize.height
    }

    /// Retrieves codec information either from a cache or by searching the statistics array.
    private mutating func codec(
        for codecId: String
    ) -> StreamRTCStatistics? {
        if let codec = codecs[codecId] {
            return codec
        } else if let codec = statistics.first(where: { $0.type == RTCStatisticType.codec.rawValue && $0.id == codecId }) {
            codecs[codecId] = codec
            return codec
        } else {
            return nil
        }
    }
}

