//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class WebRTCDecoderStatsItemTransformer: ConsumableBucketItemTransformer {

    private var previousOutput: Stream_Video_Sfu_Models_PerformanceStats?

    init() {}

    func transform(
        _ input: CallStatsReport
    ) -> [Stream_Video_Sfu_Models_PerformanceStats] {
        guard
            let stats = input.publisherRawStats
        else {
            return []
        }

        let processingUnits = stats
            .statistics
            .filter { $0.value.type == "inbound-rtp" }
            .map { ProcessingUnit($0.value) }
            .filter { $0.kind == "video" }

        guard
            let processingUnit = processingUnits.max(by: { $0.area < $1.area }),
            let codecStatistics = input.publisherRawStats?.statistics[processingUnit.codecId],
            let mediaSource = input.publisherRawStats?.statistics[processingUnit.mediaSourceId] as? RTCStatistics,
            let trackIdentifier = mediaSource.values["trackIdentifier"] as? String,
            let trackType = input.trackToKindMap[trackIdentifier]
        else {
            return []
        }

        let previousEvent = previousOutput
        let deltaTotalDecodeTime = processingUnit.totalDecodeTime - Double(previousEvent?.avgFrameTimeMs ?? 0)
        let deltaFramesDecoded = processingUnit.framesDecoded - Int(previousEvent?.avgFps ?? 0)
        let framesDecodeTime = deltaFramesDecoded > 0 ? (deltaTotalDecodeTime / Double(deltaFramesDecoded)) * 1000 : 0

        var item = Stream_Video_Sfu_Models_PerformanceStats()
        item.trackType = trackType == .video ? .video : trackType == .screenshare ? .screenShare : .unspecified
        item.codec = .init()
        item.codec.name = String((codecStatistics.values["mimeType"] as? String ?? "").split(separator: "/").last ?? "")
        item.codec.clockRate = (codecStatistics.values["clockRate"] as? UInt32) ?? 0
        item.codec.payloadType = (codecStatistics.values["payloadType"] as? UInt32) ?? 0
        item.codec.fmtp = (codecStatistics.values["sdpFmtpLine"] as? String) ?? ""
        item.avgFrameTimeMs = Float(framesDecodeTime)
        item.avgFps = Float(deltaFramesDecoded)
        item.videoDimension.width = UInt32(processingUnit.frameWidth)
        item.videoDimension.height = UInt32(processingUnit.frameHeight)

        previousOutput = item
        return [item]
    }
}

extension WebRTCDecoderStatsItemTransformer {
    struct ProcessingUnit {
        var kind: String
        var codecId: String
        var framesDecoded: Int
        var framesPerSecond: Int
        var totalDecodeTime: TimeInterval
        var trackIdentifier: String
        var frameHeight: Int
        var frameWidth: Int
        var area: Int { frameWidth * frameHeight }
        var mediaSourceId: String

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

    struct Codec {
        var name: String
        var clockRate: Int
        var payloadType: Int
        var fmtp: String
    }
}
