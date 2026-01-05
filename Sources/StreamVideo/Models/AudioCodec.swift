//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents different audio codecs.
public enum AudioCodec: String, CustomStringConvertible, Sendable {
    case opus
    case red
    case unknown

    /// Returns the raw value of the codec, which corresponds to its name.
    public var description: String {
        rawValue
    }

    /// Initializes an `AudioCodec` instance from WebRTC codec parameters.
    ///
    /// This initializer maps a WebRTC codec (`RTCRtpCodecParameters`) to the
    /// corresponding `AudioCodec` value. If the codec name matches `opus` or
    /// `red`, the respective case is assigned; otherwise, it defaults to
    /// `.unknown`.
    ///
    /// - Parameter source: The `RTCRtpCodecParameters` object containing codec
    ///   details such as the codec name.
    init(_ source: RTCRtpCodecParameters) {
        switch source.name.lowercased() {
        case AudioCodec.opus.rawValue:
            self = .opus
        case AudioCodec.red.rawValue:
            self = .red
        default:
            self = .unknown
        }
    }

    /// Initializes an `AudioCodec` instance from SFU codec model parameters.
    ///
    /// This initializer maps an SFU codec model (`Stream_Video_Sfu_Models_Codec`)
    /// to the corresponding `AudioCodec` value. If the codec name matches `opus`
    /// or `red`, the respective case is assigned; otherwise, it defaults to
    /// `.unknown`.
    ///
    /// - Parameter source: The `Stream_Video_Sfu_Models_Codec` object containing
    ///   codec details such as the codec name.
    init(_ source: Stream_Video_Sfu_Models_Codec) {
        switch source.name.lowercased() {
        case AudioCodec.opus.rawValue:
            self = .opus
        case AudioCodec.red.rawValue:
            self = .red
        default:
            self = .unknown
        }
    }
}
