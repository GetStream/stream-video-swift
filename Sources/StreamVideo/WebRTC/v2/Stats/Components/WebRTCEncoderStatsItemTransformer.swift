//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class WebRTCEncoderStatsItemTransformer: FlushableBucketItemTransformer {

    private var previousOutput: Stream_Video_Sfu_Models_PerformanceStats?

    init() {}

    func transform(
        _ input: CallStatsReport
    ) -> Stream_Video_Sfu_Models_PerformanceStats? {
        guard
            let stats = input.publisherRawStats,
            let rtp = stats.statistics.first(where: { $0.value.type == "outbound-rtp" })
        else {
            return nil
        }

        let processingUnit = ProcessingUnit(rtp.value)

        guard
            processingUnit.kind != "audio",
            let codecStatistics = input.publisherRawStats?.statistics[processingUnit.codecId]
        else {
            return nil
        }

        let previousEvent = previousOutput
        let deltaTotalEncodeTime = processingUnit.totalEncodeTime - Double(previousEvent?.avgFrameTimeMs ?? 0)
        let deltaFramesSent = processingUnit.framesSent - Int(previousEvent?.avgFps ?? 0)
        let framesEncodeTime = deltaFramesSent > 0 ? (deltaTotalEncodeTime / Double(deltaFramesSent)) * 1000 : 0

        // TODO: Implement track type lookup based on trackIdentifier
//        if
//            let mediaSource = report.publisherRawStats?.statistics.values[processingUnit.mediaSourceId] as? RTCStatistics,
//            let trackIdentifier = mediaSource.values["trackIdentifier"] as? String
//        {
//
//        }

        var item = Stream_Video_Sfu_Models_PerformanceStats()
        item.trackType = .video
        item.codec = .init()
        item.codec.name = String((codecStatistics.values["mimeType"] as? String ?? "").split(separator: "/").last ?? "")
        item.codec.clockRate = (codecStatistics.values["clockRate"] as? UInt32) ?? 0
        item.codec.payloadType = (codecStatistics.values["payloadType"] as? UInt32) ?? 0
        item.codec.fmtp = (codecStatistics.values["sdpFmtpLine"] as? String) ?? ""
        item.avgFrameTimeMs = Float(framesEncodeTime)
        item.avgFps = Float(deltaFramesSent)
        item.videoDimension.width = UInt32(processingUnit.frameWidth)
        item.videoDimension.height = UInt32(processingUnit.frameHeight)

        previousOutput = item
        return item
    }
}

extension WebRTCEncoderStatsItemTransformer {
    private struct ProcessingUnit {
        var codecId: String
        var framesSent: Int
        var kind: String
        var id: String
        var totalEncodeTime: TimeInterval
        var framesPerSecond: Int
        var frameHeight: Int
        var frameWidth: Int
        var mediaSourceId: String

        init(_ source: RTCStatistics) {
            codecId = source.values["codecId"] as? String ?? ""
            framesSent = source.values["framesSent"] as? Int ?? 0
            kind = source.values["kind"] as? String ?? ""
            id = source.values["id"] as? String ?? ""
            totalEncodeTime = source.values["totalEncodeTime"] as? TimeInterval ?? 0
            framesPerSecond = source.values["framesPerSecond"] as? Int ?? 0
            frameHeight = source.values["frameHeight"] as? Int ?? 0
            frameWidth = source.values["frameWidth"] as? Int ?? 0
            mediaSourceId = source.values["mediaSourceId"] as? String ?? ""
        }
    }

    private struct Codec {
        var name: String
        var clockRate: Int
        var payloadType: Int
        var fmtp: String
    }
}
