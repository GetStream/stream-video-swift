//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

final class VideoLayerFactory {

    func videoLayers(
        for publishOption: Stream_Video_Sfu_Models_PublishOption,
        qualities: [VideoLayer.Quality] = [.full, .half, .quarter]
    ) -> [VideoLayer] {
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
                sfuQuality: .init(quality)
            )

            videoLayers.append(videoLayer)
            scaleDownFactor *= 2
        }

        return videoLayers.reversed()
    }
}
