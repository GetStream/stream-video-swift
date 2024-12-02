//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PublishOptions: Sendable, Hashable {

    struct TrackEntry: Sendable, Hashable {
        var videoCodec: VideoCodec
        var bitrate: Int
        var frameRate: Int
        var maxSpatialLayers: Int
        var maxTemporalLayers: Int
        var dimensions: CGSize

        init(
            videoCodec: VideoCodec,
            bitrate: Int,
            frameRate: Int,
            maxSpatialLayers: Int,
            maxTemporalLayers: Int,
            dimensions: CGSize
        ) {
            self.videoCodec = videoCodec
            self.bitrate = bitrate
            self.frameRate = frameRate
            self.maxSpatialLayers = maxSpatialLayers
            self.maxTemporalLayers = maxTemporalLayers
            self.dimensions = dimensions
        }

        init(_ source: Stream_Video_Sfu_Models_PublishOption) {
            videoCodec = .init(source.codec) ?? .h264
            bitrate = Int(source.bitrate)
            frameRate = Int(source.fps)
            maxSpatialLayers = Int(source.maxSpatialLayers)
            maxTemporalLayers = Int(source.maxTemporalLayers)
            dimensions = .init(
                width: Int(source.videoDimension.width),
                height: Int(source.videoDimension.width)
            )
        }

        static let defaultVideoTrackEntry = TrackEntry(
            videoCodec: .h264,
            bitrate: VideoLayer.full.maxBitrate,
            frameRate: 30,
            maxSpatialLayers: 1,
            maxTemporalLayers: 3,
            dimensions: .init(
                width: Int(VideoLayer.full.dimensions.width),
                height: Int(VideoLayer.full.dimensions.height)
            )
        )

        static let defaultScreenShareTrackEntry = TrackEntry(
            videoCodec: .h264,
            bitrate: VideoLayer.screenshare.maxBitrate,
            frameRate: 15,
            maxSpatialLayers: 1,
            maxTemporalLayers: 3,
            dimensions: .init(
                width: Int(VideoLayer.screenshare.dimensions.width),
                height: Int(VideoLayer.screenshare.dimensions.height)
            )
        )
    }

    var videoTrack: TrackEntry

    var screenShareTrack: TrackEntry

    init(
        videoTrack: TrackEntry = .defaultVideoTrackEntry,
        screenShareTrack: TrackEntry = .defaultScreenShareTrackEntry
    ) {
        self.videoTrack = videoTrack
        self.screenShareTrack = screenShareTrack
    }

    init(publishOptions: [Stream_Video_Sfu_Models_PublishOption]) {
        var videoTrack: TrackEntry?
        var screenShareTrack: TrackEntry?

        for publishOption in publishOptions {
            switch publishOption.trackType {
            case .video:
                videoTrack = .init(publishOption)
            case .screenShare:
                screenShareTrack = .init(publishOption)
            default:
                break
            }
        }

        self.init(
            videoTrack: videoTrack ?? .defaultVideoTrackEntry,
            screenShareTrack: screenShareTrack ?? .defaultScreenShareTrackEntry
        )
    }

    func update(
        with publishOption: Stream_Video_Sfu_Models_PublishOption
    ) -> Self {
        var result = self

        switch publishOption.trackType {
        case .video:
            result.videoTrack = .init(publishOption)
        case .screenShare:
            result.screenShareTrack = .init(publishOption)
        default:
            break
        }

        return result
    }
}
