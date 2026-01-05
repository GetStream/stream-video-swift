//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Transforms raw WebRTC statistics into structured performance analytics
/// items for reporting to the SFU.
///
/// This transformer is capable of processing both encoder (outbound-rtp)
/// and decoder (inbound-rtp) stats depending on the provided mode.
/// It normalizes track stats into a type-safe structure and extracts key
/// performance metrics such as frame rate, dimensions, codec info, and more.
final class WebRTCStatsItemTransformer: ConsumableBucketItemTransformer {

    /// Determines the transformation mode: encoding (outbound-rtp) or decoding (inbound-rtp).
    enum Mode { case encoder, decoder }

    /// Stores the previously emitted performance stats per track type.
    ///
    /// Used to calculate delta values for frame rate and encode/decode time
    /// between reporting intervals.
    private var previousOutput: [TrackType: Stream_Video_Sfu_Models_PerformanceStats] = [:]

    /// The active transformation mode for this instance.
    private let mode: Mode

    /// Initializes a new stats item transformer for a specific mode.
    ///
    /// - Parameter mode: Whether this transformer handles encoding or decoding stats.
    init(mode: Mode) { self.mode = mode }

    /// Transforms the provided stats and track type mapping into SFU performance stats.
    ///
    /// - Parameter input: A tuple containing the full mutable RTC statistics report
    ///   and a mapping from track identifiers to their corresponding `TrackType`.
    /// - Returns: An array of performance stats items, or an empty array if stats
    ///   are not available or not enough data is present.
    func transform(
        _ input: (stats: MutableRTCStatisticsReport, trackToKindMap: [String: TrackType])
    ) -> [Stream_Video_Sfu_Models_PerformanceStats] {
        // Step 1: Filter and map statistics for the current mode.
        let filtered: [WebRTCItemTransformerProcessingUnit]
        switch mode {
        case .encoder:
            filtered = input.stats.statistics.values
                .filter { $0.type == "outbound-rtp" }
                .map(WebRTCItemTransformerProcessingUnit.encoder)
                .filter { $0.kind != "audio" }
        case .decoder:
            filtered = input.stats.statistics.values
                .filter { $0.type == "inbound-rtp" }
                .map(WebRTCItemTransformerProcessingUnit.decoder)
                .filter { $0.kind == "video" }
        }

        // For encoder: take first video track. For decoder: take largest area video.
        guard let processingUnit = (mode == .encoder ? filtered.first : filtered.max { $0.area < $1.area }) else {
            previousOutput = [:]
            return []
        }

        // Lookup supplementary statistics needed for detailed reporting.
        let mediaSourceStat = input.stats.statistics[processingUnit.mediaSourceId]
        let codecStat = input.stats.statistics[processingUnit.codecId]

        // Ensure required stats and mapping are present.
        guard
            let codecStatistics = codecStat,
            let mediaSource = mediaSourceStat,
            let trackIdentifier: String = mediaSource.value(for: .trackIdentifier),
            let trackType = input.trackToKindMap[trackIdentifier]
        else { return [] }

        // Calculate deltas for frame time and fps, using previous stats if present.
        let prev = previousOutput[trackType]
        let deltaTotalTime = processingUnit.totalTime - Double(prev?.avgFrameTimeMs ?? 0)
        let deltaFrames = processingUnit.frames - Int(prev?.avgFps ?? 0)
        let frameTimeMs = deltaFrames > 0 ? (deltaTotalTime / Double(deltaFrames)) * 1000 : 0

        // Populate the output stats structure.
        var item = Stream_Video_Sfu_Models_PerformanceStats()
        item.trackType = trackType == .video ? .video : trackType == .screenshare ? .screenShare : .unspecified
        item.codec = .init()
        item.codec.name = String((codecStatistics.value(for: .mimeType, fallback: "")).split(separator: "/").last ?? "")
        item.codec.clockRate = codecStatistics.value(for: .clockRate, fallback: 0)
        item.codec.payloadType = codecStatistics.value(for: .payloadType, fallback: 0)
        item.codec.fmtp = codecStatistics.value(for: .sdpFmtpLine, fallback: "")
        item.avgFrameTimeMs = Float(frameTimeMs)
        item.avgFps = Float(deltaFrames)
        item.videoDimension.width = UInt32(processingUnit.frameWidth)
        item.videoDimension.height = UInt32(processingUnit.frameHeight)
        if let target = processingUnit.targetBitrate {
            item.targetBitrate = Int32(target)
        }

        // Cache this output for use in the next delta calculation.
        previousOutput[trackType] = item
        return [item]
    }
}
