//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCConfiguration {
        
    static func makeConfiguration(
        with iceServersConfig: [ICEServer]
    ) -> RTCConfiguration {
        let configuration = RTCConfiguration()
        var iceServers = [RTCIceServer]()
        for iceServerConfig in iceServersConfig {
            let iceServer = RTCIceServer(
                urlStrings: iceServerConfig.urls,
                username: iceServerConfig.username,
                credential: iceServerConfig.password
            )
            iceServers.append(iceServer)
        }
        configuration.iceServers = iceServers
        configuration.sdpSemantics = .unifiedPlan

        /// https://linear.app/stream/issue/IOS-777/implement-max-bundle-rtcpeerconnection-policy
        configuration.bundlePolicy = .maxBundle
        return configuration
    }
}
