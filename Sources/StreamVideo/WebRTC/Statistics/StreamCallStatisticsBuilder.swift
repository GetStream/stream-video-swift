//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct StreamCallStatisticsBuilder {

    enum TrackKind: String, Equatable { case video, audio }
    enum Direction: String, Equatable { case inbound = "inbound-rtp", outbound = "outbound-rtp" }
    private enum RTCStatisticKey: String { case trackIdentifier, codecId }
    private enum RTCStatisticType: String { case codec, transport, candidatePair = "candidate-pair" }
    private enum RTCTransportDtlsState: String { case connected }

    var statistics: [StreamRTCStatistics]
    var timestamp: TimeInterval
    var trackKind: TrackKind
    var direction: Direction

    lazy var participantsReport: ParticipantsStats = makeParticipantsReport()
    lazy var aggregatedReport: AggregatedStatsReport = makeAggregatedReport()

    private var codecs: [String: StreamRTCStatistics] = [:]

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

    private mutating func makeParticipantsReport() -> ParticipantsStats {
        let videoStatistics = statistics
            .filter {
                guard
                    $0.kind == trackKind.rawValue,
                    $0.stringValue(RTCStatisticKey.trackIdentifier.rawValue) != nil
                else {
                    return false
                }
                return true
            }

        let report = videoStatistics.reduce(into: [String: [BaseStats]]()) { partialResult, videoStatistic in
            guard let trackIdentifier: String = videoStatistic.trackIdentifier else {
                return
            }
            let baseStats = makeBaseStats(for: videoStatistic)
            if partialResult[trackIdentifier] == nil {
                partialResult[trackIdentifier] = []
            }
            partialResult[trackIdentifier]?.append(baseStats)
        }

        return ParticipantsStats(
            report: report
        )
    }

    private mutating func makeAggregatedReport() -> AggregatedStatsReport {
        return aggregate(format())
    }

    private mutating func format() -> [BaseStats] {
        let result: [BaseStats] = statistics
            .filter {
                $0.type == direction.rawValue
                && $0.kind == trackKind.rawValue
            }
            .map { makeBaseStats(for: $0) }

        return result
    }

    private func aggregate(
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

        guard !baseStats.isEmpty else { return result }

        var qualityLimitationReasons: Set<String> = []
        for baseStat in baseStats {
            result.totalBytesSent += baseStat.bytesSent
            result.totalBytesReceived += baseStat.bytesReceived
            result.averageJitterInMs += baseStat.jitter
            result.averageRoundTripTimeInMs += baseStat.currentRoundTripTime
            qualityLimitationReasons.insert(baseStat.qualityLimitationReason)
            let statSize = CGSize(width: baseStat.frameWidth, height: baseStat.frameHeight)
            let aggregatedSize = CGSize(width: result.highestFrameWidth, height: result.highestFrameHeight)
            if contains(size: statSize, within: aggregatedSize) {
                result.highestFrameWidth = baseStat.frameWidth
                result.highestFrameHeight = baseStat.frameHeight
                result.highestFramesPerSecond = baseStat.framesPerSecond
            }
        }

        let count = Double(baseStats.endIndex)
        if count > 0 {
            result.averageJitterInMs = (result.averageJitterInMs / count) * 1000
            result.averageRoundTripTimeInMs = (result.averageRoundTripTimeInMs / count) * 1000
        }
        result.qualityLimitationReasons = qualityLimitationReasons
            .sorted()
            .joined(separator: ",")

        return result
    }

    private func contains(
        size containerSize: CGSize,
        within containedSize: CGSize
    ) -> Bool {
        containerSize.width >= containedSize.width
        && containerSize.height >= containedSize.height
    }

    private mutating func makeBaseStats(
        for rtcStreamStats: StreamRTCStatistics
    ) -> BaseStats {
        var roundTripTime: Double = 0.0

        if
            let transport = statistics.first(where: { $0.type == RTCStatisticType.transport.rawValue && $0.id == rtcStreamStats.transportId }),
            transport.dtlsState == RTCTransportDtlsState.connected.rawValue,
            let selectedCandidatePairId: String = transport.selectedCandidatePairId,
            let candidatePairStatistic = statistics.first(where: { $0.type == RTCStatisticType.candidatePair.rawValue && $0.id == selectedCandidatePairId }),
            let currentRoundTripTime: Double = candidatePairStatistic.currentRoundTripTime
        {
            roundTripTime = currentRoundTripTime
        }

        let codec: StreamRTCStatistics? = rtcStreamStats
            .stringValue(RTCStatisticKey.codecId.rawValue)
            .map { self.codec(for: $0) } ?? nil

        return BaseStats(
            bytesSent: rtcStreamStats.bytesSent ?? 0,
            bytesReceived: rtcStreamStats.bytesReceived ?? 0,
            codec: codec?.mimeType ?? "",
            currentRoundTripTime: roundTripTime,
            frameWidth: rtcStreamStats.frameWidth ?? 0,
            frameHeight: rtcStreamStats.frameHeight ?? 0,
            framesPerSecond: rtcStreamStats.framesPerSecond ?? 0,
            jitter: rtcStreamStats.jitter ?? 0,
            kind: rtcStreamStats.kind ?? trackKind.rawValue,
            qualityLimitationReason: rtcStreamStats.qualityLimitationReason ?? "",
            rid: rtcStreamStats.rid ?? "",
            ssrc: rtcStreamStats.ssrc ?? 0,
            isPublisher: direction == .outbound
        )
    }

    private mutating func codec(for codecId: String) -> StreamRTCStatistics? {
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
