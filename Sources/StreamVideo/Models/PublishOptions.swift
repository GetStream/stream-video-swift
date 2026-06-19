//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents options for publishing audio and video tracks.
///
/// This structure encapsulates configurations for audio, video, and screen-sharing
/// tracks, including codec, bitrate, frame rate, and dimensions.
struct PublishOptions: Sendable, Hashable {

    /// Options for configuring audio publishing.
    struct AudioPublishOptions: Sendable, Hashable, CustomStringConvertible {
        /// Unique identifier for the audio stream.
        var id: Int
        /// Codec used for the audio stream.
        var codec: AudioCodec
        /// Bitrate allocated for the audio stream, measured in bits per second.
        var bitrate: Int

        /// A string representation of the audio publish options.
        var description: String {
            "AudioPublishOptions(id: \(id), codec: \(codec), bitrate: \(bitrate))"
        }

        /// Initializes audio options from a server model.
        ///
        /// - Parameter publishOption: The audio publish option model from the server.
        init(_ publishOption: Stream_Video_Sfu_Models_PublishOption) {
            id = Int(publishOption.id)
            codec = .init(publishOption.codec)
            bitrate = Int(publishOption.bitrate)
        }

        /// Initializes audio options with specific parameters.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the audio stream.
        ///   - codec: Codec for the audio stream.
        ///   - bitrate: Bitrate for the audio stream. Defaults to `0`.
        init(
            id: Int = 0,
            codec: AudioCodec,
            bitrate: Int = 0
        ) {
            self.id = id
            self.codec = codec
            self.bitrate = bitrate
        }

        /// Combines properties into a hash value for use in hash-based collections.
        ///
        /// - Parameter hasher: The hasher used to compute the hash value.
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }

        static func == (
            lhs: AudioPublishOptions,
            rhs: AudioPublishOptions
        ) -> Bool {
            lhs.id == rhs.id && lhs.codec == rhs.codec
        }
    }

    /// Options for configuring video publishing.
    struct VideoPublishOptions: Sendable, Hashable {

        /// Represents spatial and temporal layers for video capturing.
        struct CapturingLayers: Sendable, Hashable, CustomStringConvertible {
            /// Number of spatial layers for the video stream.
            var spatialLayers: Int
            /// Number of temporal layers for the video stream.
            var temporalLayers: Int

            /// Scalability mode string derived from spatial and temporal layers.
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

            /// A string representation of the capturing layers.
            var description: String {
                "CapturingLayers(spatial: \(spatialLayers), temporal: \(temporalLayers), scalabilityMode: \(scalabilityMode))"
            }
        }

        /// Unique identifier for the video stream.
        var id: Int
        /// Codec used for the video stream.
        var codec: VideoCodec
        /// Layers for video capturing, defining spatial and temporal layers.
        var capturingLayers: CapturingLayers
        /// Bitrate allocated for the video stream, measured in bits per second.
        var bitrate: Int
        /// Frame rate of the video stream, measured in frames per second.
        var frameRate: Int
        /// Dimensions of the video stream, specified in width and height.
        var dimensions: CGSize
        /// Represents the codec parameters formatted as a string. It will either
        /// be provided by the source or it should be derived by using
        /// `PeerConnectionFactory.codecCapabilities(videoCodec)?.fmtp`
        var fmtp: String

        /// Initializes video options from a server model.
        ///
        /// - Parameter publishOption: The video publish option model from the server.
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
            fmtp = publishOption.codec.fmtp
        }

        /// Initializes video options with specific parameters.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the video stream.
        ///   - codec: Codec used for the video stream.
        ///   - capturingLayers: Video capturing layers. Defaults to `.maxSpatialLayers`
        ///   spatial and `.maxTemporalLayers` temporal layers.
        ///   - bitrate: Bitrate for the video stream. Defaults to `.maxBitrate`.
        ///   - frameRate: Frame rate for the video stream. Defaults to `30`.
        ///   - dimensions: Dimensions of the video stream. Defaults to `.full`.
        init(
            id: Int = 0,
            codec: VideoCodec,
            fmtp: String = "",
            capturingLayers: PublishOptions.VideoPublishOptions.CapturingLayers = .init(
                spatialLayers: .maxSpatialLayers,
                temporalLayers: .maxTemporalLayers
            ),
            bitrate: Int = .maxBitrate,
            frameRate: Int = .defaultFrameRate,
            dimensions: CGSize = .full
        ) {
            self.id = id
            self.codec = codec
            self.fmtp = fmtp
            self.capturingLayers = capturingLayers
            self.bitrate = bitrate
            self.frameRate = frameRate
            self.dimensions = dimensions
        }

        /// Combines properties into a hash value for use in hash-based collections.
        ///
        /// - Parameter hasher: The hasher used to compute the hash value.
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(codec)
        }

        static func == (
            lhs: VideoPublishOptions,
            rhs: VideoPublishOptions
        ) -> Bool {
            lhs.id == rhs.id && lhs.codec == rhs.codec
        }
        
        /// Builds video layers for the specified track type.
        ///
        /// This method creates an array of `Stream_Video_Sfu_Models_VideoLayer`
        /// objects based on the current video publish options and the specified
        /// track type. The layers are configured with appropriate bitrate, frameRate
        /// dimensions and resolution identifiers (RIDs). Then the layers are being
        /// reversed and remapped their RIDs based on their position in the array.
        ///
        /// - Parameter trackType: The type of track for which to build layers
        ///   (e.g., video or screen share).
        /// - Returns: An array of `Stream_Video_Sfu_Models_VideoLayer` objects.
        func buildLayers(for trackType: TrackType) -> [Stream_Video_Sfu_Models_VideoLayer] {
            let publishOption = Stream_Video_Sfu_Models_PublishOption(
                self,
                trackType: trackType == .video ? .video : .screenShare
            )

            let result = publishOption
                .videoLayers(spatialLayersRequired: capturingLayers.spatialLayers)
                .enumerated()
                .map { (offset, element) in
                    let scaleDownFactor = max(1, offset * 2)
                    var result = Stream_Video_Sfu_Models_VideoLayer()
                    result.rid = element.quality.rawValue
                    result.bitrate = UInt32(bitrate / scaleDownFactor)
                    result.fps = UInt32(frameRate)
                    result.videoDimension = .init()
                    result.videoDimension.width = UInt32(dimensions.width / CGFloat(scaleDownFactor))
                    result.videoDimension.height = UInt32(dimensions.height / CGFloat(scaleDownFactor))
                    return result
                }
                .reversed()
                .prepare()

            if result.endIndex != capturingLayers.spatialLayers {
                log.warning(
                    "Capturing layers should match the generated trackInfo layers.",
                    subsystems: .sfu
                )
            }

            return result
        }
    }

    /// Original publish option models received from the server.
    let source: [Stream_Video_Sfu_Models_PublishOption]
    /// Configured options for publishing audio tracks.
    let audio: [AudioPublishOptions]
    /// Configured options for publishing video tracks.
    let video: [VideoPublishOptions]
    /// Configured options for publishing screen-sharing tracks.
    let screenShare: [VideoPublishOptions]

    /// Initializes the publish options from a list of server models.
    ///
    /// - Parameter publishOptions: The server-provided list of publish options.
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

    /// Initializes the publish options with audio, video, and screen-sharing configurations.
    ///
    /// - Parameters:
    ///   - audio: List of audio publish options. Defaults to an empty list.
    ///   - video: List of video publish options. Defaults to an empty list.
    ///   - screenShare: List of screen-sharing publish options. Defaults to an empty list.
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
}
