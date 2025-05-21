//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class WebRTCEncoderStatsItemTransformer: ConsumableBucketItemTransformer {

    private var previousOutput: [TrackType: Stream_Video_Sfu_Models_PerformanceStats] = [:]

    init() {}

    func transform(
        _ input: CallStatsReport
    ) -> [Stream_Video_Sfu_Models_PerformanceStats] {

        var result = [Stream_Video_Sfu_Models_PerformanceStats]()

        let _outbounds = input
            .publisherRawStats?
            .statistics
            .filter { $0.value.type == "outbound-rtp" }
            .compactMap(\.value)
        let outbounds = _outbounds ?? []

        guard
            !outbounds.isEmpty
        else {
            previousOutput = [:]
            return result
        }

        for outbound in outbounds {
            let processingUnit = ProcessingUnit(outbound)

            guard
                processingUnit.kind != "audio",
                let codecStatistics = input.publisherRawStats?.statistics[processingUnit.codecId],
                let mediaSource = input.publisherRawStats?.statistics[processingUnit.mediaSourceId] as? RTCStatistics,
                let trackIdentifier = mediaSource.values["trackIdentifier"] as? String,
                let trackType = input.trackToKindMap[trackIdentifier]
            else {
                continue
            }

            let previousEvent = previousOutput[trackType]
            let deltaTotalEncodeTime = processingUnit.totalEncodeTime - Double(previousEvent?.avgFrameTimeMs ?? 0)
            let deltaFramesSent = processingUnit.framesSent - Int(previousEvent?.avgFps ?? 0)
            let framesEncodeTime = deltaFramesSent > 0 ? (deltaTotalEncodeTime / Double(deltaFramesSent)) * 1000 : 0

            var item = Stream_Video_Sfu_Models_PerformanceStats()
            item.trackType = trackType == .video ? .video : trackType == .screenshare ? .screenShare : .unspecified
            item.codec = .init()
            item.codec.name = String((codecStatistics.values["mimeType"] as? String ?? "").split(separator: "/").last ?? "")
            item.codec.clockRate = (codecStatistics.values["clockRate"] as? UInt32) ?? 0
            item.codec.payloadType = (codecStatistics.values["payloadType"] as? UInt32) ?? 0
            item.codec.fmtp = (codecStatistics.values["sdpFmtpLine"] as? String) ?? ""
            item.avgFrameTimeMs = Float(framesEncodeTime)
            item.avgFps = Float(deltaFramesSent)
            item.videoDimension.width = UInt32(processingUnit.frameWidth)
            item.videoDimension.height = UInt32(processingUnit.frameHeight)
            item.targetBitrate = Int32(processingUnit.targetBitrate)

            result.append(item)
        }

        previousOutput = [:]
        result.forEach {
            switch $0.trackType {
            case .video:
                previousOutput[.video] = $0
            case .screenShare:
                previousOutput[.screenshare] = $0
            default:
                break
            }
        }

        return result
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
        var targetBitrate: Int

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
            targetBitrate = source.values["targetBitrate"] as? Int ?? 0
        }
    }

    private struct Codec {
        var name: String
        var clockRate: Int
        var payloadType: Int
        var fmtp: String
    }
}
