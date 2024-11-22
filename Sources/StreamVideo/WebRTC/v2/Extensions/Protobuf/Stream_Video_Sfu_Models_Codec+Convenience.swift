//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension adding a convenience initializer for `Stream_Video_Sfu_Models_Codec`.
extension Stream_Video_Sfu_Models_Codec {

    /// Initializes a `Stream_Video_Sfu_Models_Codec` from an `RTCRtpCodecCapability`.
    ///
    /// This initializer converts the codec capability information from the WebRTC
    /// layer (`RTCRtpCodecCapability`) into a `Stream_Video_Sfu_Models_Codec` model.
    ///
    /// - Parameter source: The `RTCRtpCodecCapability` to convert.
    ///
    /// - Note:
    ///   - `name` is mapped directly from the codec's name.
    ///   - `fmtp` represents the codec parameters formatted as a string.
    ///   - `clockRate` is converted from the codec's `clockRate` to `UInt32` or
    ///     defaults to `0` if absent.
    ///   - `payloadType` is derived from the codec's `preferredPayloadType` or
    ///     defaults to `0` if absent.
    init(_ source: RTCRtpCodecCapability) {
        name = source.name
        fmtp = source.fmtp
        clockRate = source.clockRate?.uint32Value ?? 0
        payloadType = source.preferredPayloadType?.uint32Value ?? 0
    }
}
