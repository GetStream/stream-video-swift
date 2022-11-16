//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct EndpointConfig {
    let hostname: String
    let wsEndpoint: String
}

extension EndpointConfig {
    static let localhostConfig = EndpointConfig(
        hostname: "http://192.168.0.132:26991/rpc",
        wsEndpoint: "ws://192.168.0.132:8989/rpc/stream.video.coordinator.client_v1_rpc.Websocket/Connect"
    )
    
    static let stagingConfig = EndpointConfig(
        hostname: "https://rpc-video-coordinator.oregon-v1.stream-io-video.com/rpc",
        wsEndpoint: "wss://wss-video-coordinator.oregon-v1.stream-io-video.com/rpc/stream.video.coordinator.client_v1_rpc.Websocket/Connect"
    )
}
