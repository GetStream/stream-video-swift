//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCRtpEncodingParameters {

    /// Convenience initializer to create an `RTCRtpEncodingParameters` instance from a `VideoCodec`.
    ///
    /// This initializer allows for easy creation of RTP encoding parameters based on
    /// the properties of a given video codec. It sets up the RTP encoding with the
    /// quality, maximum bitrate, and optional scale-down factor from the codec.
    ///
    /// - Parameter codec: The `VideoCodec` instance to use for initializing the encoding parameters.
    ///
    /// - Note:
    ///   - The `rid` (Restriction Identifier) is set to the codec's quality.
    ///   - The `maxBitrateBps` is set to the codec's maximum bitrate.
    ///   - If the codec has a `scaleDownFactor`, it's applied to `scaleResolutionDownBy`.
    ///   - For scalable codecs (SVC), the default `scalabilityMode` is set to `"L3T2_KEY"`.
    convenience init(
        _ layer: VideoLayer,
        preferredVideoCodec: VideoCodec?
    ) {
        self.init()
        rid = layer.quality.rawValue
        maxBitrateBps = (layer.maxBitrate) as NSNumber
        if preferredVideoCodec?.isSVC == true {
            scalabilityMode = "L3T2_KEY"
        } else {
            if let scaleDownFactor = layer.scaleDownFactor {
                scaleResolutionDownBy = (scaleDownFactor) as NSNumber
            }
        }
    }

    /// Convenience initializer to create an `RTCRtpEncodingParameters` instance.
    ///
    /// This initializer configures the RTP encoding parameters using the properties
    /// of a given `VideoLayer` and `VideoPublishOptions`. It is particularly useful
    /// for setting up video track encoding with scalability and resolution settings.
    ///
    /// - Parameters:
    ///   - layer: The `VideoLayer` representing the quality, bitrate, and scaling
    ///     properties for the video encoding.
    ///   - videoPublishOptions: The `VideoPublishOptions` specifying codec,
    ///     frame rate, and capturing layers for the video track.
    ///
    /// - Note:
    ///   - The `rid` (Restriction Identifier) is set to the layer's quality value.
    ///   - The `maxFramerate` is derived from the `frameRate` in `videoPublishOptions`.
    ///   - The `maxBitrateBps` is set to the layer's maximum bitrate.
    ///   - For scalable codecs (SVC), the `scalabilityMode` is derived from
    ///     `videoPublishOptions.capturingLayers.scalabilityMode`.
    ///   - If the codec is not SVC, the `scaleResolutionDownBy` is applied
    ///     based on the `scaleDownFactor` from the `layer`.
    convenience init(
        _ layer: VideoLayer,
        videoPublishOptions: PublishOptions.VideoPublishOptions,
        frameRate: Int,
        bitrate: Int,
        scaleDownFactor: Int = 1
    ) {
        self.init()
        rid = layer.quality.rawValue
        maxFramerate = frameRate as NSNumber
        maxBitrateBps = bitrate as NSNumber
        if videoPublishOptions.codec.isSVC {
            scalabilityMode = videoPublishOptions.capturingLayers.scalabilityMode
        } else {
            scaleResolutionDownBy = scaleDownFactor as NSNumber
        }
    }
}
