//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Models_VideoLayer {
    
    init(
        _ codec: VideoCodec,
        fps: UInt32 = 30
    ) {
        bitrate = UInt32(codec.maxBitrate)
        rid = codec.quality
        var dimension = Stream_Video_Sfu_Models_VideoDimension()
        dimension.height = UInt32(codec.dimensions.height)
        dimension.width = UInt32(codec.dimensions.width)
        videoDimension = dimension
        quality = codec.sfuQuality
        self.fps = fps
    }
}
