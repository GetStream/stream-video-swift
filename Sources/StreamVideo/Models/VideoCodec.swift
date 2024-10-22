//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public enum VideoCodec: String, Sendable {
    case h264, vp8, vp9, av1

    var isSVC: Bool {
        switch self {
        case .vp9, .av1:
            return true
        case .h264, .vp8:
            return false
        }
    }

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
