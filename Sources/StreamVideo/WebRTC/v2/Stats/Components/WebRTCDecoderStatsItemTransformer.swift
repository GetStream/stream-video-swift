//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A transformer that converts raw WebRTC decoder statistics into a consumable
/// format representing performance stats for video decoding.
final class WebRTCDecoderStatsItemTransformer: ConsumableBucketItemTransformer {

    /// Stores the previous output stats to calculate deltas over time.
    private var previousOutput: Stream_Video_Sfu_Models_PerformanceStats?

    /// Initializes a new instance of the transformer.
    init() {}

    /// Transforms a `CallStatsReport` into an array of performance stats items.
    ///
    /// - Parameter input: The raw call statistics report containing publisher stats.
    /// - Returns: An array of performance stats, typically containing one item or empty.
    func transform(
        _ input: CallStatsReport
    ) -> [Stream_Video_Sfu_Models_PerformanceStats] {
        // Ensure that publisher raw stats are available; otherwise return empty.
        guard
            let stats = input.publisherRawStats
        else {
            return []
        }

        // Filter statistics to those of type "inbound-rtp" and map to ProcessingUnit.
        // Then filter those units to only include video kind.
        let processingUnits = stats
            .statistics
            .filter { $0.value.type == "inbound-rtp" }
            .map { ProcessingUnit($0.value) }
            .filter { $0.kind == "video" }

        // Select the processing unit with the largest video frame area.
        // Obtain codec and media source statistics for that unit.
        // Retrieve the track identifier and map it to a track type.
        guard
            let processingUnit = processingUnits.max(by: { $0.area < $1.area }),
            let codecStatistics = input.publisherRawStats?.statistics[processingUnit.codecId],
            let mediaSource = input.publisherRawStats?.statistics[processingUnit.mediaSourceId] as? RTCStatistics,
            let trackIdentifier = mediaSource.values["trackIdentifier"] as? String,
            let trackType = input.trackToKindMap[trackIdentifier]
        else {
            // Return empty if any required data is missing.
            return []
        }

        // Reference the previous output event to calculate deltas.
        let previousEvent = previousOutput
        // Calculate the difference in total decode time since last event.
        let deltaTotalDecodeTime = processingUnit.totalDecodeTime - Double(previousEvent?.avgFrameTimeMs ?? 0)
        // Calculate the difference in frames decoded since last event.
        let deltaFramesDecoded = processingUnit.framesDecoded - Int(previousEvent?.avgFps ?? 0)
        // Compute average frame decode time in milliseconds if frames decoded > 0.
        let framesDecodeTime = deltaFramesDecoded > 0 ? (deltaTotalDecodeTime / Double(deltaFramesDecoded)) * 1000 : 0

        // Create a new performance stats item and populate its fields.
        var item = Stream_Video_Sfu_Models_PerformanceStats()
        // Map internal track type to the protocol buffer enum.
        item.trackType = trackType == .video ? .video : trackType == .screenshare ? .screenShare : .unspecified
        // Initialize codec information.
        item.codec = .init()
        // Extract codec name from the MIME type string.
        item.codec.name = String((codecStatistics.values["mimeType"] as? String ?? "").split(separator: "/").last ?? "")
        // Set codec clock rate, payload type, and format parameters.
        item.codec.clockRate = (codecStatistics.values["clockRate"] as? UInt32) ?? 0
        item.codec.payloadType = (codecStatistics.values["payloadType"] as? UInt32) ?? 0
        item.codec.fmtp = (codecStatistics.values["sdpFmtpLine"] as? String) ?? ""
        // Set average frame decode time and frames per second.
        item.avgFrameTimeMs = Float(framesDecodeTime)
        item.avgFps = Float(deltaFramesDecoded)
        // Set video dimensions based on the processing unit's frame size.
        item.videoDimension.width = UInt32(processingUnit.frameWidth)
        item.videoDimension.height = UInt32(processingUnit.frameHeight)

        // Cache the current output for use in the next transformation.
        previousOutput = item
        // Return the array containing the single performance stats item.
        return [item]
    }
}

extension WebRTCDecoderStatsItemTransformer {
    /// Represents a processing unit extracted from RTC statistics, typically an
    /// inbound RTP video stream with associated decoding metrics.
    struct ProcessingUnit {
        /// The media kind, e.g., "video".
        var kind: String
        /// The identifier for the associated codec statistics.
        var codecId: String
        /// The total number of frames decoded.
        var framesDecoded: Int
        /// The frames per second rate reported.
        var framesPerSecond: Int
        /// The total decode time accumulated.
        var totalDecodeTime: TimeInterval
        /// The identifier for the media track.
        var trackIdentifier: String
        /// The height of the video frame in pixels.
        var frameHeight: Int
        /// The width of the video frame in pixels.
        var frameWidth: Int
        /// The computed area of the frame (width * height).
        var area: Int { frameWidth * frameHeight }
        /// The identifier for the associated media source statistics.
        var mediaSourceId: String

        /// Initializes a ProcessingUnit from a given RTCStatistics instance.
        ///
        /// - Parameter source: The RTCStatistics object to extract values from.
        init(_ source: RTCStatistics) {
            kind = source.values["kind"] as? String ?? ""
            codecId = source.values["codecId"] as? String ?? ""
            framesDecoded = source.values["framesDecoded"] as? Int ?? 0
            framesPerSecond = source.values["framesPerSecond"] as? Int ?? 0
            totalDecodeTime = source.values["totalDecodeTime"] as? TimeInterval ?? 0
            trackIdentifier = source.values["trackIdentifier"] as? String ?? ""
            frameHeight = source.values["frameHeight"] as? Int ?? 0
            frameWidth = source.values["frameWidth"] as? Int ?? 0
            mediaSourceId = source.values["mediaSourceId"] as? String ?? ""
        }
    }

    /// Represents codec information for performance statistics.
    struct Codec {
        /// The codec's name (e.g., "VP8", "H264").
        var name: String
        /// The codec clock rate in Hz.
        var clockRate: Int
        /// The payload type identifier.
        var payloadType: Int
        /// The format parameters string (fmtp).
        var fmtp: String
    }
}
