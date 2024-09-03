//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCPeerConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new:
            return "new"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown/default"
        }
    }
}
