//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

final class VideoLayerFactory {

    func defaultVideoLayers() -> [VideoLayer] {
        var publishOption = Stream_Video_Sfu_Models_PublishOption()
        publishOption.codec = .init()
        publishOption.codec.name = "h264"
        publishOption.trackType = .video
        publishOption.bitrate = Int32(Int.maxBitrate)
        publishOption.fps = 30
        publishOption.videoDimension = .init()
        publishOption.videoDimension.width = UInt32(CMVideoDimensions.full.width)
        publishOption.videoDimension.height = UInt32(CMVideoDimensions.full.height)

        return videoLayers(for: publishOption)
    }

    func videoLayers(
        for publishOption: Stream_Video_Sfu_Models_PublishOption
    ) -> [VideoLayer] {
        let qualities: [VideoLayer.Quality] = [.full, .half, .quarter]

        let publishOptionWidth = Int(publishOption.videoDimension.width)
        let publishOptionHeight = Int(publishOption.videoDimension.height)
        let publishOptionBitrate = Int(publishOption.bitrate)

        var scaleDownFactor: Int = 1

        var videoLayers: [VideoLayer] = []
        for quality in qualities {
            let width = publishOptionWidth / scaleDownFactor
            let height = publishOptionHeight / scaleDownFactor
            let bitrate = publishOptionBitrate / Int(scaleDownFactor)
            let dimensions = CMVideoDimensions(width: Int32(width), height: Int32(height))

            let videoLayer = VideoLayer(
                dimensions: dimensions,
                quality: quality,
                maxBitrate: bitrate,
                sfuQuality: {
                    switch quality {
                    case .full:
                        return .high
                    case .half:
                        return .mid
                    case .quarter:
                        return .lowUnspecified
                    }
                }()
            )

            videoLayers.append(videoLayer)
            scaleDownFactor *= 2
        }

        return videoLayers.reversed()
    }
}
