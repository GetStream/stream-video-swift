//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents supported video codecs for WebRTC communication.
///
/// Each codec corresponds to a specific encoding and transmission standard
/// for video data, such as H.264 or VP8. This enumeration also provides
/// utility methods for determining codec features and initializing codecs
/// from various input sources.
public enum VideoCodec: String, Sendable, Hashable, CustomStringConvertible {
    /// Represents an unknown or unsupported video codec.
    case unknown
    /// Represents the H.264 video codec, widely used for video streaming.
    case h264
    /// Represents the VP8 video codec, commonly used in WebRTC applications.
    case vp8
    /// Represents the VP9 video codec, known for its efficiency and SVC support.
    case vp9
    /// Represents the AV1 video codec, offering advanced compression features.
    case av1

    public var description: String {
        rawValue
    }

    /// Indicates whether the codec supports Scalable Video Coding (SVC).
    ///
    /// Scalable Video Coding allows multiple layers (e.g., resolutions or
    /// qualities) to be encoded into a single stream. This property is `true`
    /// for codecs that natively support SVC.
    var isSVC: Bool {
        switch self {
        case .vp9, .av1:
            return true
        case .h264, .vp8:
            return false
        default:
            return false
        }
    }

    /// Initializes a `VideoCodec` instance from WebRTC codec parameters.
    ///
    /// Attempts to map the codec name from `RTCRtpCodecParameters` to one
    /// of the supported `VideoCodec` cases. If no match is found, the codec
    /// is set to `.unknown`.
    ///
    /// - Parameter source: The codec parameters provided by WebRTC, containing
    ///   details such as the codec name.
    init(_ source: RTCRtpCodecParameters) {
        switch source.name.lowercased() {
        case VideoCodec.h264.rawValue:
            self = .h264
        case VideoCodec.vp8.rawValue:
            self = .vp8
        case VideoCodec.vp9.rawValue:
            self = .vp9
        case VideoCodec.av1.rawValue:
            self = .av1
        default:
            self = .unknown
        }
    }

    /// Initializes a `VideoCodec` instance from SFU codec model parameters.
    ///
    /// Attempts to map the codec name from a `Stream_Video_Sfu_Models_Codec`
    /// object to one of the supported `VideoCodec` cases. If no match is
    /// found, the codec is set to `.unknown`.
    ///
    /// - Parameter source: The codec model provided by the SFU, containing
    ///   details such as the codec name.
    init(_ source: Stream_Video_Sfu_Models_Codec) {
        switch source.name.lowercased() {
        case VideoCodec.h264.rawValue:
            self = .h264
        case VideoCodec.vp8.rawValue:
            self = .vp8
        case VideoCodec.vp9.rawValue:
            self = .vp9
        case VideoCodec.av1.rawValue:
            self = .av1
        default:
            self = .unknown
        }
    }
}
