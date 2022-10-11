//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

extension RTCConfiguration {
        
    static func makeConfiguration(with iceServersConfig: [ICEServerConfig]) -> RTCConfiguration {
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
        return configuration
    }
}
