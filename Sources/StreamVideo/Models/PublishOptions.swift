//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PublishOptions: Sendable, Hashable {

    struct AudioPublishOptions: Sendable, Hashable, CustomStringConvertible {
        var id: Int
        var codec: AudioCodec
        var bitrate: Int

        var description: String {
            "AudioPublishOptions(id: \(id), codec: \(codec), bitrate: \(bitrate))"
        }

        init(_ publishOption: Stream_Video_Sfu_Models_PublishOption) {
            id = Int(publishOption.id)
            codec = .init(publishOption.codec)
            bitrate = Int(publishOption.bitrate)
        }

        init(
            id: Int,
            codec: AudioCodec,
            bitrate: Int = 0
        ) {
            self.id = id
            self.codec = codec
            self.bitrate = bitrate
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }
    }

    struct VideoPublishOptions: Sendable, Hashable {
        struct CapturingLayers: Sendable, Hashable, CustomStringConvertible {
            var spatialLayers: Int
            var temporalLayers: Int

            var scalabilityMode: String {
                var components = [
                    "L",
                    "\(spatialLayers)",
                    "T",
                    "\(temporalLayers)"
                ]

                if spatialLayers > 1 {
                    components.append("_KEY")
                }
                return components.joined()
            }

            var description: String {
                "CapturingLayers(spatial: \(spatialLayers), temporal: \(temporalLayers), scalabilityMode: \(scalabilityMode))"
            }
        }

        var id: Int
        var codec: VideoCodec
        var capturingLayers: CapturingLayers
        var bitrate: Int
        var frameRate: Int
        var dimensions: CGSize

        init(_ publishOption: Stream_Video_Sfu_Models_PublishOption) {
            id = Int(publishOption.id)
            codec = .init(publishOption.codec)
            capturingLayers = .init(
                spatialLayers: Int(publishOption.maxSpatialLayers),
                temporalLayers: Int(publishOption.maxTemporalLayers)
            )
            bitrate = Int(publishOption.bitrate)
            frameRate = Int(publishOption.fps)
            dimensions = .init(
                width: Int(publishOption.videoDimension.width),
                height: Int(publishOption.videoDimension.height)
            )
        }

        init(
            id: Int = -1,
            codec: VideoCodec,
            capturingLayers: PublishOptions.VideoPublishOptions.CapturingLayers = .init(spatialLayers: 3, temporalLayers: 1),
            bitrate: Int = .maxBitrate,
            frameRate: Int = 30,
            dimensions: CGSize = .full
        ) {
            self.id = id
            self.codec = codec
            self.capturingLayers = capturingLayers
            self.bitrate = bitrate
            self.frameRate = frameRate
            self.dimensions = dimensions
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }
    }

    let source: [Stream_Video_Sfu_Models_PublishOption]
    let audio: [AudioPublishOptions]
    let video: [VideoPublishOptions]
    let screenShare: [VideoPublishOptions]

    init(_ publishOptions: [Stream_Video_Sfu_Models_PublishOption]) {
        var audio = [AudioPublishOptions]()
        var video = [VideoPublishOptions]()
        var screenShare = [VideoPublishOptions]()

        for publishOption in publishOptions {
            switch publishOption.trackType {
            case .audio:
                audio.append(.init(publishOption))
            case .video:
                video.append(.init(publishOption))
            case .screenShare:
                screenShare.append(.init(publishOption))
            default:
                break
            }
        }

        source = publishOptions
        self.audio = audio
        self.video = video
        self.screenShare = screenShare
    }

    init(
        audio: [AudioPublishOptions] = [],
        video: [VideoPublishOptions] = [],
        screenShare: [VideoPublishOptions] = []
    ) {
        var source: [Stream_Video_Sfu_Models_PublishOption] = []
        source.append(
            contentsOf: audio.map(Stream_Video_Sfu_Models_PublishOption.init)
        )
        source.append(
            contentsOf: video
                .map { Stream_Video_Sfu_Models_PublishOption($0, trackType: .video) }
        )
        source.append(
            contentsOf: screenShare
                .map { Stream_Video_Sfu_Models_PublishOption($0, trackType: .screenShare) }
        )

        self.source = source
        self.audio = audio
        self.video = video
        self.screenShare = screenShare
    }

    // MARK: - VideoLayers

    func videoLayers(
        for trackType: TrackType,
        codec: VideoCodec
    ) -> [VideoLayer] {
        []
    }

    // MARK: - Empty

    static let `default` = PublishOptions(
        video: [.init(codec: .h264)],
        screenShare: [.init(codec: .h264, frameRate: 20)]
    )
}

extension CGSize {
    static let full = CGSize(width: 1280, height: 720)
}

extension Stream_Video_Sfu_Models_PublishOption {

    init(_ source: PublishOptions.AudioPublishOptions) {
        trackType = .audio
        codec = .init()
        codec.name = source.codec.rawValue
        bitrate = Int32(source.bitrate)
    }

    init(_ source: PublishOptions.VideoPublishOptions, trackType: Stream_Video_Sfu_Models_TrackType) {
        self.trackType = trackType
        codec = .init()
        codec.name = source.codec.rawValue
        bitrate = Int32(source.bitrate)
        fps = Int32(source.frameRate)
        videoDimension = .init()
        videoDimension.width = UInt32(source.dimensions.width)
        videoDimension.height = UInt32(source.dimensions.height)
        maxSpatialLayers = Int32(source.capturingLayers.spatialLayers)
        maxTemporalLayers = Int32(source.capturingLayers.temporalLayers)
    }
}
