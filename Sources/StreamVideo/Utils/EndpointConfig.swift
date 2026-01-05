//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct EndpointConfig {
    let hostname: String
    let wsEndpoint: String
    var baseVideoURL: String {
        "\(hostname)"
    }
}

extension EndpointConfig {
    static let production = EndpointConfig(
        hostname: "https://video.stream-io-api.com",
        wsEndpoint: "wss://video.stream-io-api.com/video/connect"
    )
    
    static let localhostConfig = EndpointConfig(
        hostname: "http://localhost:3030/",
        wsEndpoint: "ws://localhost:8800/video/connect"
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
            "X-Stream-Client": SystemEnvironment.xStreamClientHeader
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
