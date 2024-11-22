//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents supported audio codecs in the StreamVideo SDK.
///
/// - `none`: Represents an unsupported or unknown codec.
/// - `opus`: Represents the Opus codec, widely used for audio streaming.
/// - `red`: Represents the RED codec, used for redundant audio streams.
public enum AudioCodec: String, Sendable, Hashable {
    case none, opus, red

    public var description: String {
        rawValue
    }

    /// Initializes an `AudioCodec` from WebRTC codec parameters.
    ///
    /// - Parameter source: The `RTCRtpCodecParameters` containing codec details.
    /// - Assigns `.opus` or `.red` based on the codec name, or `.none` by default.
    init(_ source: RTCRtpCodecParameters) {
        switch source.name.lowercased() {
        case AudioCodec.opus.rawValue:
            self = .opus
        case AudioCodec.red.rawValue:
            self = .red
        default:
            self = .none
        }
    }

    /// Initializes an `AudioCodec` from SFU codec model parameters.
    ///
    /// - Parameter source: The `Stream_Video_Sfu_Models_Codec` containing codec details.
    /// - Assigns `.opus` or `.red` based on the codec name, or `.none` by default.
    init(_ source: Stream_Video_Sfu_Models_Codec) {
        switch source.name.lowercased() {
        case AudioCodec.opus.rawValue:
            self = .opus
        case AudioCodec.red.rawValue:
            self = .red
        default:
            self = .none
        }
    }
}
