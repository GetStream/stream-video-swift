//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpTransceiverInit {
    /// Convenience initializer for creating an `RTCRtpTransceiverInit` with specific parameters.
    ///
    /// This initializer provides a more Swift-friendly way to create an `RTCRtpTransceiverInit` object,
    /// allowing you to specify the track type, direction, stream IDs, and optional video codecs.
    ///
    /// - Parameters:
    ///   - trackType: The type of track (e.g., audio, video, or screenshare).
    ///   - direction: The desired direction for the transceiver (e.g., sendRecv, sendOnly, recvOnly).
    ///   - streamIds: An array of stream IDs associated with this transceiver.
    ///   - codecs: An optional array of video codecs to be used. If provided, these will be used to create RTP encoding parameters.
    ///
    /// - Note: If the track type is screenshare, all send encodings will be set to active.
    convenience init(
        trackType: TrackType,
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        layers: [VideoLayer]? = nil,
        preferredVideoCodec: VideoCodec? = nil
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds
        if let layers {
            var sendEncodings = layers
                .map { RTCRtpEncodingParameters($0, preferredVideoCodec: preferredVideoCodec) }

            if preferredVideoCodec?.isSVC == true {
                sendEncodings = sendEncodings
                    .filter { $0.rid == "f" }
                sendEncodings.first?.rid = "q"
                self.sendEncodings = sendEncodings
            } else {
                self.sendEncodings = sendEncodings
            }
        }
        
        if trackType == .screenshare {
            sendEncodings.forEach { $0.isActive = true }
        }
    }

    convenience init(
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        audioOptions: PublishOptions.AudioPublishOptions
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds
    }

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
        let videoLayers = VideoLayerFactory()
            .videoLayers(for: publishOption)

        var sendEncodings = videoLayers
            .map { RTCRtpEncodingParameters($0, videoPublishOptions: videoOptions) }

        if videoOptions.codec.isSVC {
            sendEncodings = sendEncodings
                .filter { $0.rid == VideoLayer.full.quality.rawValue }
            sendEncodings.first?.rid = VideoLayer.quarter.quality.rawValue
        }

        if trackType == .screenshare {
            sendEncodings.forEach { $0.isActive = true }
        }

        self.sendEncodings = sendEncodings

        log.debug(
            """
            RTCRtpTransceiverInit from VideoPublishOptions:
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
