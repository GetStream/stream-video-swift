//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension to make RTCIceConnectionState conform to CustomStringConvertible.
extension RTCIceConnectionState {

    /// A textual representation of the ICE connection state.
    public var description: String {
        switch self {
        case .new:
            return "new"
        case .checking:
            return "checking"
        case .connected:
            return "connected"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .disconnected:
            return "disconnected"
        case .closed:
            return "closed"
        case .count:
            return "count"
        @unknown default:
            return "unknown"
        }
    }
}
