//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extends `RTCRtpTransceiverDirection` to conform to the `CustomStringConvertible` protocol.
extension RTCRtpTransceiverDirection {
    /// A textual representation of the RTP transceiver direction.
    ///
    /// This property provides a human-readable string for each possible direction of an RTCRtpTransceiver.
    /// It's useful for debugging, logging, and displaying the current direction to users or developers.
    ///
    /// - Returns: A string describing the transceiver direction:
    ///   - "sendRecv" for bidirectional communication
    ///   - "sendOnly" for outbound-only communication
    ///   - "recvOnly" for inbound-only communication
    ///   - "inactive" when the transceiver is not actively sending or receiving
    ///   - "stopped" when the transceiver has been stopped
    ///   - "unknown/default" for any future, undefined directions
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
