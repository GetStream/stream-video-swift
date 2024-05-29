//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct EndpointConfig {
    public let hostname: String
    public let wsEndpoint: String
    public var baseVideoURL: String { hostname }

    public init(hostname: String, wsEndpoint: String) {
        self.hostname = hostname
        self.wsEndpoint = wsEndpoint
    }

    public static let production = EndpointConfig(
        hostname: "https://video.stream-io-api.com",
        wsEndpoint: "wss://video.stream-io-api.com/video/connect"
    )
}

enum EndpointConfigProviderKey: InjectionKey {
    static var currentValue: EndpointConfig = .production
}

extension InjectedValues {
    public var endpointConfig: EndpointConfig {
        get { Self[EndpointConfigProviderKey.self] }
        set { Self[EndpointConfigProviderKey.self] = newValue }
    }
}

extension EndpointConfig {
    
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
