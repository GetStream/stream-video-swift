//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpTransceiverInit {

    /// Creates a temporary `RTCRtpTransceiverInit` instance for a specific track type.
    ///
    /// This utility method is used to create a temporary configuration for a transceiver,
    /// tailored to the given track type (audio, video, or screen share). It provides
    /// a default setup suitable for testing or initialization scenarios where the
    /// specific track details are not yet available.
    ///
    /// - Parameter trackType: The type of track (e.g., audio, video, or screen share).
    /// - Returns: A configured `RTCRtpTransceiverInit` instance.
    ///
    /// - Note:
    ///   - For `.audio`, a temporary stream ID of `"temp-audio"` is used with a default
    ///     audio configuration (`AudioPublishOptions` with `.none` codec).
    ///   - For `.video` or `.screenshare`, a temporary stream ID is assigned based on
    ///     the track type (`"temp-video"` for video or `"temp-screenshare"` for screen share),
    ///     with default `VideoPublishOptions` using the H.264 codec.
    ///   - For other cases, an empty `RTCRtpTransceiverInit` instance is returned.
    static func temporary(
        trackType: TrackType
    ) -> RTCRtpTransceiverInit {
        switch trackType {
        case .audio:
            return .init(
                direction: .sendOnly,
                streamIds: ["temp-audio"],
                audioOptions: .init(id: 0, codec: .unknown)
            )
        case .video, .screenshare:
            return .init(
                trackType: trackType,
                direction: .sendOnly,
                streamIds: [
                    trackType == .video ? "temp-video" : "temp-screenshare"
                ],
                videoOptions: .init(
                    codec: .h264,
                    capturingLayers: trackType == .video
                        ? .init(spatialLayers: 3, temporalLayers: 1)
                        : .init(spatialLayers: 1, temporalLayers: 1)
                )
            )
        default:
            return .init()
        }
    }

    /// Convenience initializer for creating an `RTCRtpTransceiverInit` for audio tracks.
    ///
    /// This initializer provides a streamlined way to set up a transceiver specifically
    /// for audio tracks, allowing configuration of the direction and associated stream IDs.
    ///
    /// - Parameters:
    ///   - direction: The desired direction for the transceiver (e.g., sendRecv, sendOnly, recvOnly).
    ///   - streamIds: An array of stream IDs associated with this transceiver.
    ///   - audioOptions: The `AudioPublishOptions` defining codec and bitrate configurations
    ///     for the audio track.
    ///
    /// - Note:
    ///   - The `direction` determines how the transceiver interacts with the track (e.g., sending,
    ///     receiving, or both).
    ///   - The `audioOptions` provide the necessary details for setting up the audio codec and
    ///     configuring the bitrate for optimal performance.
    convenience init(
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        audioOptions: PublishOptions.AudioPublishOptions
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds

        log.debug(
            """
            RTCRtpTransceiverInit from AudioPublishOptions:
                AudioCodec: \(audioOptions.codec)
                Bitrate: \(audioOptions.bitrate)
            """
        )
    }

    /// Convenience initializer for creating an `RTCRtpTransceiverInit` for video tracks.
    ///
    /// This initializer simplifies the creation of a transceiver specifically for
    /// video tracks, allowing configuration of the track type, direction, associated
    /// stream IDs, and video publishing options.
    ///
    /// - Parameters:
    ///   - trackType: The type of track (e.g., video or screen share).
    ///   - direction: The desired direction for the transceiver (e.g., sendRecv, sendOnly, recvOnly).
    ///   - streamIds: An array of stream IDs associated with this transceiver.
    ///   - videoOptions: The `VideoPublishOptions` specifying codec, frame rate, bitrate,
    ///     capturing layers, and resolution for the video track.
    ///
    /// - Note:
    ///   - Video layers are generated using `VideoLayerFactory` based on the provided
    ///     `videoOptions` and track type.
    ///   - If the codec supports SVC (Scalable Video Coding), the send encodings are
    ///     filtered to retain only the highest quality (`.full`) layer, and its `rid`
    ///     (Restriction Identifier) is adjusted to use the `.quarter` layer.
    ///   - For screen share tracks, all send encodings are set to active.
    convenience init(
        trackType: TrackType,
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        videoOptions: PublishOptions.VideoPublishOptions
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds

        let publishOption = Stream_Video_Sfu_Models_PublishOption(
            videoOptions,
            trackType: trackType == .video ? .video : .screenShare
        )

        let videoLayers = publishOption.videoLayers(
            spatialLayersRequired: videoOptions.capturingLayers.spatialLayers
        )

        let sendEncodings = videoLayers
            .enumerated()
            .map {
                let scaleDownFactor = max(1, 2 * $0.offset)
                return RTCRtpEncodingParameters(
                    $0.element,
                    videoPublishOptions: videoOptions,
                    frameRate: videoOptions.frameRate,
                    bitrate: videoOptions.bitrate / scaleDownFactor,
                    scaleDownFactor: scaleDownFactor
                )
            }
            .reversed()
            .filter {
                if videoOptions.codec.isSVC {
                    return $0.rid == VideoLayer.Quality.full.rawValue
                } else {
                    return true
                }
            }
            .prepare()

        if trackType == .screenshare {
            sendEncodings.forEach { $0.isActive = true }
        }

        self.sendEncodings = sendEncodings

        log.debug(
            """
            RTCRtpTransceiverInit for trackType:\(trackType) from VideoPublishOptions:
                VideoCodec: \(videoOptions.codec)
                Bitrate: \(videoOptions.bitrate)
                FrameRate: \(videoOptions.frameRate)
                Dimensions: \(videoOptions.dimensions)
                CapturingLayers
                    Spatial: \(videoOptions.capturingLayers.spatialLayers)
                    Temporal: \(videoOptions.capturingLayers.temporalLayers)
                    ScalabilityMode: \(videoOptions.capturingLayers.scalabilityMode)
            
            Created with:
                VideoLayers: \(videoLayers.map(\.quality.rawValue).joined(separator: ","))
                SendEncodings: \(sendEncodings.compactMap(\.rid).joined(separator: ","))
            """
        )
    }
}
