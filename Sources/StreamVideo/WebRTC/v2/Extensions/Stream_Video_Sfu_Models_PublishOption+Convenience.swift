//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension Stream_Video_Sfu_Models_PublishOption {

    init(
        trackType: Stream_Video_Sfu_Models_TrackType,
        codec: Stream_Video_Sfu_Models_Codec,
        bitrate: Int,
        maxSpatialLayer: Int = 3
    ) {
        self.trackType = trackType
        self.codec = codec
        self.bitrate = Int32(bitrate)
        maxSpatialLayers = Int32(maxSpatialLayer)
    }
}
