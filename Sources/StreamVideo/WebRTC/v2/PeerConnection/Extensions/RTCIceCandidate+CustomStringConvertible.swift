//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCIceCandidate {
    /// Provides a detailed string representation of the RTCIceCandidate.
    ///
    /// This description includes:
    /// - The SDP (Session Description Protocol) Mid
    /// - The SDP MLineIndex
    /// - The full SDP string
    /// - The server URL (if available)
    override public var description: String {
        """
        RTCIceCandidate:
        - SDP Mid: \(sdpMid ?? "nil")
        - SDP MLineIndex: \(sdpMLineIndex)
        - SDP: \(sdp)
        - Server URL: \(serverUrl ?? "nil")
        """
    }
}
