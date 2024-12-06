//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public enum AudioCodec: String, Sendable, Hashable {
    case none, opus, red

    public var description: String {
        rawValue
    }

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
