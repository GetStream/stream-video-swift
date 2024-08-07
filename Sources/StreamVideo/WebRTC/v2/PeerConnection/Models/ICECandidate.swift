//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct ICECandidate: Codable {
    var candidate: String
    var sdpMid: String?
    var sdpMLineIndex: Int32

    init(from candidate: RTCIceCandidate) {
        self.candidate = candidate.sdp
        sdpMid = candidate.sdpMid
        sdpMLineIndex = candidate.sdpMLineIndex
    }
}
