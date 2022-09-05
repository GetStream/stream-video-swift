//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

extension RTCConfiguration {
    
    static var `default`: RTCConfiguration {
        let configuration = RTCConfiguration()
        let first = RTCIceServer(urlStrings: ["stun:openrelay.metered.ca:80"])
        let second = RTCIceServer(
            urlStrings: ["turn:openrelay.metered.ca:80"],
            username: "openrelayproject",
            credential: "openrelayproject"
        )
        let third = RTCIceServer(
            urlStrings: ["turn:openrelay.metered.ca:443"],
            username: "openrelayproject",
            credential: "openrelayproject"
        )
        let fourth = RTCIceServer(
            urlStrings: ["turn:openrelay.metered.ca:443?transport=tcp"],
            username: "openrelayproject",
            credential: "openrelayproject"
        )
        configuration.iceServers = [first, second, third, fourth]
        configuration.sdpSemantics = .unifiedPlan
        return configuration
    }
}
