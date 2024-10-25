//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    /// - Note: The `rid` (Restriction Identifier) is set to the codec's quality.
    ///         The `maxBitrateBps` is set to the codec's maximum bitrate.
    ///         If the codec has a `scaleDownFactor`, it's applied to `scaleResolutionDownBy`.
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
}
