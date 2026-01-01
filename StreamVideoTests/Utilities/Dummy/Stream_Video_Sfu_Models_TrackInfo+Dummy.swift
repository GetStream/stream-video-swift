//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Models_TrackInfo {
    static func dummy(
        trackID: String = .unique,
        trackType: Stream_Video_Sfu_Models_TrackType,
        layers: [Stream_Video_Sfu_Models_VideoLayer] = [],
        mid: String
    ) -> Stream_Video_Sfu_Models_TrackInfo {
        var result = Stream_Video_Sfu_Models_TrackInfo()
        result.trackID = trackID
        result.trackType = trackType
        result.layers = layers
        result.mid = mid
        return result
    }
}

extension Stream_Video_Sfu_Models_VideoLayer {
    static func dummy(
        rid: String = .unique,
        videoDimension: Stream_Video_Sfu_Models_VideoDimension = .dummy(),
        bitrate: UInt32 = 1000,
        fps: UInt32 = 30,
        quality: Stream_Video_Sfu_Models_VideoQuality = .high
    ) -> Stream_Video_Sfu_Models_VideoLayer {
        var result = Stream_Video_Sfu_Models_VideoLayer()
        result.rid = rid
        result.videoDimension = videoDimension
        result.bitrate = bitrate
        result.fps = fps
        result.quality = quality
        return result
    }
}

extension Stream_Video_Sfu_Models_VideoDimension {
    static func dummy(
        width: UInt32 = 1920,
        height: UInt32 = 1080
    ) -> Stream_Video_Sfu_Models_VideoDimension {
        var result = Stream_Video_Sfu_Models_VideoDimension()
        result.width = width
        result.height = height
        return result
    }
}

extension Stream_Video_Sfu_Models_VideoQuality {
    static func dummy(
        rawValue: Int = 2
    ) -> Stream_Video_Sfu_Models_VideoQuality {
        Stream_Video_Sfu_Models_VideoQuality(rawValue: rawValue) ?? .high
    }
}
