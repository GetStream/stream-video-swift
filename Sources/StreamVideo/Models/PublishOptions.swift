//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents options for publishing audio and video tracks.
///
/// This structure encapsulates configurations for audio, video, and screen-sharing
/// tracks, such as codec, bitrate, frame rate, and dimensions.
struct PublishOptions: Sendable, Hashable {

    /// Options for configuring audio publishing.
    struct AudioPublishOptions: Sendable, Hashable, CustomStringConvertible {
        /// Unique identifier for the audio stream.
        var id: Int
        /// Codec used for the audio stream.
        var codec: AudioCodec
        /// Bitrate allocated for the audio stream.
        var bitrate: Int

        /// A string describing the audio publish options.
        var description: String {
            "AudioPublishOptions(id: \(id), codec: \(codec), bitrate: \(bitrate))"
        }

        /// Initializes the audio options from a model.
        ///
        /// - Parameter publishOption: The audio publish option model.
        init(_ publishOption: Stream_Video_Sfu_Models_PublishOption) {
            id = Int(publishOption.id)
            codec = .init(publishOption.codec)
            bitrate = Int(publishOption.bitrate)
        }

        /// Initializes the audio options with given parameters.
        ///
        /// - Parameters:
        ///   - id: The unique identifier for the audio stream.
        ///   - codec: The codec for the audio stream.
        ///   - bitrate: The bitrate for the audio stream. Defaults to `0`.
        init(
            id: Int = 0,
            codec: AudioCodec,
            bitrate: Int = 0
        ) {
            self.id = id
            self.codec = codec
            self.bitrate = bitrate
        }

        /// Hashes the essential properties into the given hasher.
        ///
        /// - Parameter hasher: The hasher used to combine values.
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }
    }

    /// Options for configuring video publishing.
    struct VideoPublishOptions: Sendable, Hashable {

        /// Represents spatial and temporal layers for video capturing.
        struct CapturingLayers: Sendable, Hashable, CustomStringConvertible {
            /// Number of spatial layers for the video.
            var spatialLayers: Int
            /// Number of temporal layers for the video.
            var temporalLayers: Int

            /// Scalability mode derived from spatial and temporal layers.
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

            /// A string describing the capturing layers.
            var description: String {
                "CapturingLayers(spatial: \(spatialLayers), temporal: \(temporalLayers), " +
                    "scalabilityMode: \(scalabilityMode))"
            }
        }

        /// Unique identifier for the video stream.
        var id: Int
        /// Codec used for the video stream.
        var codec: VideoCodec
        /// Layers for video capturing.
        var capturingLayers: CapturingLayers
        /// Bitrate allocated for the video stream.
        var bitrate: Int
        /// Frame rate for the video stream.
        var frameRate: Int
        /// Dimensions of the video stream.
        var dimensions: CGSize

        /// Initializes the video options from a model.
        ///
        /// - Parameter publishOption: The video publish option model.
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

        /// Initializes the video options with given parameters.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the video stream.
        ///   - codec: Codec used for the video stream.
        ///   - capturingLayers: Video capturing layers. Defaults to 3 spatial and 1 temporal layer.
        ///   - bitrate: Bitrate for the video stream. Defaults to `.maxBitrate`.
        ///   - frameRate: Frame rate for the video stream. Defaults to `30`.
        ///   - dimensions: Video dimensions. Defaults to `.full`.
        init(
            id: Int = -1,
            codec: VideoCodec,
            capturingLayers: PublishOptions.VideoPublishOptions.CapturingLayers = .init(spatialLayers: 3, temporalLayers: 1),
            bitrate: Int = .maxBitrate,
            frameRate: Int = .defaultFrameRate,
            dimensions: CGSize = .full
        ) {
            self.id = id
            self.codec = codec
            self.capturingLayers = capturingLayers
            self.bitrate = bitrate
            self.frameRate = frameRate
            self.dimensions = dimensions
        }

        /// Hashes the essential properties into the given hasher.
        ///
        /// - Parameter hasher: The hasher used to combine values.
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }
    }

    /// Original publish option models from the server.
    let source: [Stream_Video_Sfu_Models_PublishOption]
    /// Configured audio publishing options.
    let audio: [AudioPublishOptions]
    /// Configured video publishing options.
    let video: [VideoPublishOptions]
    /// Configured screen-sharing options.
    let screenShare: [VideoPublishOptions]

    /// Initializes the publish options from server models.
    ///
    /// - Parameter publishOptions: List of server-provided publish options.
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

    /// Initializes the publish options with audio, video, and screen-sharing.
    ///
    /// - Parameters:
    ///   - audio: List of audio publish options.
    ///   - video: List of video publish options.
    ///   - screenShare: List of screen-sharing options.
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

    /// Returns video layers for the given track type and codec.
    ///
    /// - Parameters:
    ///   - trackType: The type of track (e.g., video, screen share).
    ///   - codec: The video codec to use.
    /// - Returns: A list of video layers.
    func videoLayers(
        for trackType: TrackType,
        codec: VideoCodec
    ) -> [VideoLayer] {
        []
    }

    /// Default publish options.
    static let `default` = PublishOptions(
        video: [.init(codec: .h264)],
        screenShare: [.init(codec: .h264, frameRate: 20)]
    )
}
