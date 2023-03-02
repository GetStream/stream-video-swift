//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    
    static let oregonStagingConfig = EndpointConfig(
        hostname: "https://video-edge-oregon-ce3.stream-io-api.com/",
        wsEndpoint: "wss://video-edge-oregon-ce3.stream-io-api.com/video/connect"
    )
    
    static let frankfurtStagingConfig = EndpointConfig(
        hostname: "https://video-edge-frankfurt-ce1.stream-io-api.com/",
        wsEndpoint: "wss://video-edge-frankfurt-ce1.stream-io-api.com/video/connect"
    )
    
    func connectQueryParams(apiKey: String) -> [String: String] {
        [
            "api_key": apiKey,
            "stream-auth-type": "jwt",
            "X-Stream-Client": "stream-video-swift"
        ]
    }
}

internal extension URL {
    func appendingQueryItems(_ items: [String: String]) throws -> URL {
        let queryItems = items.map { URLQueryItem(name: $0.key, value: $0.value) }
        return try appendingQueryItems(queryItems)
    }

    func appendingQueryItems(_ items: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            throw ClientError.InvalidURL("Can't create `URLComponents` from the url: \(self).")
        }
        let existingQueryItems = components.queryItems ?? []
        components.queryItems = existingQueryItems + items

        // Manually replace all occurrences of "+" in the query because it can be understood as a placeholder
        // value for a space. We want to keep it as "+" so we have to manually percent-encode it.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")

        guard let newURL = components.url else {
            throw ClientError.InvalidURL("Can't create a new `URL` after appending query items: \(items).")
        }
        return newURL
    }
}
