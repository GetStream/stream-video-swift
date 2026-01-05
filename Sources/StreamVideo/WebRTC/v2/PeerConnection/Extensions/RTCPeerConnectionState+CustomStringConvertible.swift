//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extends `RTCPeerConnectionState` to conform to the `CustomStringConvertible` protocol.
extension RTCPeerConnectionState {
    /// A textual representation of the peer connection state.
    ///
    /// This property provides a human-readable string for each possible state of an RTCPeerConnection.
    /// It's useful for debugging, logging, and displaying the current state to users.
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
