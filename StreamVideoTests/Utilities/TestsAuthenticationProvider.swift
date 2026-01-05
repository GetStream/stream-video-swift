//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class TestsAuthenticationProvider {
    struct TokenResponse: Codable {
        var userId: String
        var token: String
        var apiKey: String
    }

    func authenticate(
        environment: String,
        baseURL: URL,
        userId: String,
        callIds: [String] = [],
        expirationIn: Int = 0
    ) async throws -> TokenResponse {
        var url = baseURL
            .appending(.init(name: "user_id", value: userId))
            .appending(.init(name: "environment", value: environment))

        if !callIds.isEmpty {
            url = url.appending(
                URLQueryItem(
                    name: "call_cids",
                    value: callIds.joined(separator: ",")
                )
            )
        }

        if expirationIn > 0 {
            url = url.appending(
                URLQueryItem(
                    name: "exp",
                    value: "\(expirationIn)"
                )
            )
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
}

extension URL {

    var isWeb: Bool { scheme == "http" || scheme == "https" }

    var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }

    func addQueryParameter(_ key: String, value: String?) -> URL {
        if #available(iOS 16.0, *) {
            return appending(queryItems: [.init(name: key, value: value)])
        } else {
            guard
                var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
            else {
                return self
            }

            var queryItems: [URLQueryItem] = components.queryItems ?? []
            queryItems.append(.init(name: key, value: value))
            components.queryItems = queryItems

            return components.url ?? self
        }
    }

    func appending(_ queryItem: URLQueryItem) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + [queryItem]

        return components.url ?? self
    }

    var host: String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.host
    }
}
