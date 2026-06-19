//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Convenience initializers for `Stream_Video_Sfu_Models_PublishOption`.
extension Stream_Video_Sfu_Models_PublishOption {

    /// Initializes a `Stream_Video_Sfu_Models_PublishOption` with basic parameters.
    ///
    /// - Parameters:
    ///   - trackType: The type of track (e.g., audio, video, screen share).
    ///   - codec: The codec to use for the track.
    ///   - bitrate: The bitrate for the track, in bits per second.
    ///   - maxSpatialLayer: The maximum spatial layer (default is `.maxSpatialLayers`).
    init(
        trackType: Stream_Video_Sfu_Models_TrackType,
        codec: Stream_Video_Sfu_Models_Codec,
        bitrate: Int,
        maxSpatialLayer: Int = .maxSpatialLayers
    ) {
        self.trackType = trackType
        self.codec = codec
        self.bitrate = Int32(bitrate)
        maxSpatialLayers = Int32(maxSpatialLayer)
    }

    /// Initializes a `Stream_Video_Sfu_Models_PublishOption` from an audio model.
    ///
    /// Converts an instance of `PublishOptions.AudioPublishOptions` into a
    /// `Stream_Video_Sfu_Models_PublishOption`.
    ///
    /// - Parameter source: The `AudioPublishOptions` to convert.
    init(_ source: PublishOptions.AudioPublishOptions) {
        trackType = .audio
        codec = .init()
        codec.name = source.codec.rawValue
        bitrate = Int32(source.bitrate)
    }

    /// Initializes a `Stream_Video_Sfu_Models_PublishOption` from a video model.
    ///
    /// Converts an instance of `PublishOptions.VideoPublishOptions` into a
    /// `Stream_Video_Sfu_Models_PublishOption`.
    ///
    /// - Parameters:
    ///   - source: The `VideoPublishOptions` to convert.
    ///   - trackType: The type of track (e.g., video, screen share).
    init(
        _ source: PublishOptions.VideoPublishOptions,
        trackType: Stream_Video_Sfu_Models_TrackType
    ) {
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
