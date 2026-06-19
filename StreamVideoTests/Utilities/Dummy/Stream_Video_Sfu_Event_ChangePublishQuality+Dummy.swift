//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Event_ChangePublishQuality {
    static func dummy(
        audioSenders: [Stream_Video_Sfu_Event_AudioSender] = [],
        videoSenders: [Stream_Video_Sfu_Event_VideoSender] = []
    ) -> Stream_Video_Sfu_Event_ChangePublishQuality {
        var result = Stream_Video_Sfu_Event_ChangePublishQuality()
        result.audioSenders = audioSenders
        result.videoSenders = videoSenders
        return result
    }
}

extension Stream_Video_Sfu_Event_AudioSender {
    static func dummy(
        codec: AudioCodec,
        trackType: Stream_Video_Sfu_Models_TrackType = .unspecified,
        publishOptionID: Int = 0
    ) -> Stream_Video_Sfu_Event_AudioSender {
        var result = Stream_Video_Sfu_Event_AudioSender()
        result.codec = .init()
        result.codec.name = codec.rawValue
        result.trackType = trackType
        result.publishOptionID = Int32(publishOptionID)
        return result
    }
}

extension Stream_Video_Sfu_Event_VideoSender {
    static func dummy(
        codec: VideoCodec,
        trackType: Stream_Video_Sfu_Models_TrackType = .unspecified,
        layers: [Stream_Video_Sfu_Event_VideoLayerSetting] = [],
        publishOptionID: Int = 0
    ) -> Stream_Video_Sfu_Event_VideoSender {
        var result = Stream_Video_Sfu_Event_VideoSender()
        result.codec = .init()
        result.codec.name = codec.rawValue
        result.layers = layers
        result.trackType = trackType
        result.publishOptionID = Int32(publishOptionID)
        return result
    }
}
