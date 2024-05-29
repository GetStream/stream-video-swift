//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension EndpointConfig {
    static let localhostConfig = EndpointConfig(
        hostname: "http://localhost:3030/",
        wsEndpoint: "ws://localhost:8800/video/connect"
    )

    static let frankfurtStagingConfig = EndpointConfig(
        hostname: "https://video-edge-frankfurt-ce1.stream-io-api.com",
        wsEndpoint: "wss://video-edge-frankfurt-ce1.stream-io-api.com/video/connect"
    )
}
