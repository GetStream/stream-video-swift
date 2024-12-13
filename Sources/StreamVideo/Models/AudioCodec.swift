//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents supported audio codecs in the StreamVideo SDK.
///
/// This enumeration defines the audio codecs supported by the StreamVideo SDK.
/// Each case represents a specific codec used for encoding and decoding audio
/// streams.
///
/// - `unknown`: Represents an unsupported or unknown codec.
/// - `opus`: Represents the Opus codec, widely used for audio streaming due to
///   its efficiency and high-quality audio compression.
/// - `red`: Represents the RED codec, used for redundant audio streams to
///   improve reliability and resilience against packet loss.
public enum AudioCodec: String, Sendable, Hashable {
    case unknown, opus, red

    /// A textual description of the codec.
    ///
    /// Returns the raw value of the codec, which corresponds to its name.
    public var description: String {
        rawValue
    }

    /// Initializes an `AudioCodec` instance from WebRTC codec parameters.
    ///
    /// This initializer allows mapping a WebRTC codec (`RTCRtpCodecParameters`)
    /// to the corresponding `AudioCodec` value. If the codec name matches
    /// `opus` or `red`, the respective case is assigned; otherwise, it defaults
    /// to `.unknown`.
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
    /// This initializer allows mapping an SFU codec model
    /// (`Stream_Video_Sfu_Models_Codec`) to the corresponding `AudioCodec`
    /// value. If the codec name matches `opus` or `red`, the respective case
    /// is assigned; otherwise, it defaults to `.unknown`.
    ///
    /// - Parameter source: The `Stream_Video_Sfu_Models_Codec` object
    ///   containing codec details such as the codec name.
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
