//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

extension RTCConfiguration {
    
    static func makeConfiguration(with hostname: String) -> RTCConfiguration {
        let configuration = RTCConfiguration()
        let first = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        let second = RTCIceServer(
            urlStrings: ["turn:\(hostname):3478"],
            username: "video",
            credential: "video"
        )
        configuration.iceServers = [first, second]
        configuration.sdpSemantics = .unifiedPlan
        return configuration
    }
}
