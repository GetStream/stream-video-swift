//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Event_VideoSender {
    static func dummy(
        codec: Stream_Video_Sfu_Models_Codec = .dummy(),
        layers: [Stream_Video_Sfu_Event_VideoLayerSetting],
        trackType: Stream_Video_Sfu_Models_TrackType,
        publishOptionID: Int = 0
    ) -> Stream_Video_Sfu_Event_VideoSender {
        var result = Stream_Video_Sfu_Event_VideoSender()
        result.codec = codec
        result.layers = layers
        result.trackType = trackType
        result.publishOptionID = Int32(publishOptionID)
        return result
    }
}
