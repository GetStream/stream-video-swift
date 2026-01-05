//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol RTCRtpEncodingParametersProtocol {
    var rid: String? { get }
    var maxBitrateBps: NSNumber? { get }
    var maxFramerate: NSNumber? { get }
}

extension RTCRtpEncodingParameters: RTCRtpEncodingParametersProtocol {}

extension Stream_Video_Sfu_Models_VideoLayer {

    /// Initializes a `Stream_Video_Sfu_Models_VideoLayer` from a `VideoLayer`.
    ///
    /// - Parameters:
    ///   - codec: The `VideoLayer` instance containing quality and dimension details.
    ///   - fps: The frames per second for the video layer. Defaults to ``Int.defaultFrameRate``.
    ///
    /// - Note:
    ///   - Sets the `bitrate`, `rid` (Restriction Identifier), video dimensions, and quality
    ///     based on the provided `VideoLayer` instance.
    init(
        _ codec: VideoLayer,
        fps: Int = .defaultFrameRate
    ) {
        bitrate = UInt32(codec.maxBitrate)
        rid = codec.quality.rawValue
        var dimension = Stream_Video_Sfu_Models_VideoDimension()
        dimension.height = UInt32(codec.dimensions.height)
        dimension.width = UInt32(codec.dimensions.width)
        videoDimension = dimension
        quality = codec.sfuQuality
        self.fps = UInt32(fps)
    }

    /// Initializes a `Stream_Video_Sfu_Models_VideoLayer` from encoding parameters.
    ///
    /// - Parameters:
    ///   - layer: The `RTCRtpEncodingParameters` containing encoding details.
    ///   - publishOptions: The `VideoPublishOptions` providing fallback configurations.
    ///
    /// - Note:
    ///   - Uses `rid`, `maxBitrateBps`, and `maxFramerate` from the `layer` if available;
    ///     otherwise, defaults to values from `publishOptions`.
    ///   - Logs warnings if any invalid configurations are detected:
    ///     - `rid` longer or shorter than 1 character.
    ///     - `bitrate` set to `0`.
    ///     - `fps` (frames per second) set to `0`.
    ///     - Missing video dimensions.
    init(
        _ layer: RTCRtpEncodingParametersProtocol,
        publishOptions: PublishOptions.VideoPublishOptions
    ) {
        rid = layer.rid ?? (
            publishOptions.capturingLayers.spatialLayers == 1 || publishOptions.codec.isSVC
                ? "q"
                : ""
        )
        bitrate = layer.maxBitrateBps?.uint32Value ?? UInt32(publishOptions.bitrate)
        fps = layer.maxFramerate?.uint32Value ?? UInt32(publishOptions.frameRate)
        videoDimension = .init()
        videoDimension.width = UInt32(publishOptions.dimensions.width)
        videoDimension.height = UInt32(publishOptions.dimensions.height)

        if rid.count != 1 {
            log.warning(
                "Stream_Video_Sfu_Models_VideoLayer with rid longer/smaller than 1 character is invalid.",
                subsystems: .webRTC
            )
        }

        if bitrate == 0 {
            log.warning(
                "Stream_Video_Sfu_Models_VideoLayer with bitrate=0 is invalid.",
                subsystems: .webRTC
            )
        }

        if fps == 0 {
            log.warning(
                "Stream_Video_Sfu_Models_VideoLayer with fps=0 is invalid.",
                subsystems: .webRTC
            )
        }

        if !hasVideoDimension {
            log.warning(
                "Stream_Video_Sfu_Models_VideoLayer without videoDimension is invalid.",
                subsystems: .webRTC
            )
        }
    }
}
