//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpTransceiverDirection: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sendRecv:
            return "sendRecv"
        case .sendOnly:
            return "sendOnly"
        case .recvOnly:
            return "recvOnly"
        case .inactive:
            return "inactive"
        case .stopped:
            return "stopped"
        @unknown default:
            return "unknown/default"
        }
    }
}
