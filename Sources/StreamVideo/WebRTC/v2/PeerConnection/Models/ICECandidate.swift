//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents an ICE (Interactive Connectivity Establishment) candidate.
///
/// This struct is used for encoding and decoding ICE candidate information
/// when communicating with the SFU (Selective Forwarding Unit).
struct ICECandidate: Codable {
    /// The Session Description Protocol (SDP) for this ICE candidate.
    var candidate: String
    /// The media stream identification tag.
    var sdpMid: String?
    /// The index of the media description in the SDP.
    var sdpMLineIndex: Int32

    /// Initializes an ICECandidate from an RTCIceCandidate.
    ///
    /// - Parameter candidate: The RTCIceCandidate to convert.
    init(from candidate: RTCIceCandidate) {
        self.candidate = candidate.sdp
        sdpMid = candidate.sdpMid
        sdpMLineIndex = candidate.sdpMLineIndex
    }
}
