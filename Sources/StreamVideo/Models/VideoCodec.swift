//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents supported video codecs for WebRTC communication.
///
/// Each codec is associated with a specific encoding and transmission
/// standard for video data, such as H.264 or VP8.
public enum VideoCodec: String, Sendable {
    case h264, vp8, vp9, av1

    /// Determines if the codec supports Scalable Video Coding (SVC).
    ///
    /// Scalable Video Coding allows multiple video layers (e.g., resolution
    /// or quality) to be encoded into a single stream. This property is
    /// `true` for codecs that support SVC.
    var isSVC: Bool {
        switch self {
        case .vp9, .av1:
            return true
        case .h264, .vp8:
            return false
        }
    }

    /// Initializes a `VideoCodec` from `RTCRtpCodecParameters` if supported.
    ///
    /// Attempts to map the codec name in the `RTCRtpCodecParameters` to one
    /// of the supported `VideoCodec` cases. If no match is found, the
    /// initializer returns `nil`.
    ///
    /// - Parameter source: The codec parameters used to determine the codec.
    init?(_ source: RTCRtpCodecParameters) {
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
            return nil
        }
    }
}
