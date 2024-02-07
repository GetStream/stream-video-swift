//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum AuthenticationProvider {

    @MainActor
    static func createUser() async throws -> (User, String) {
        let userId = String(String.unique.prefix(8))
        let user = User(
            id: userId,
            name: userId,
            imageURL: nil,
            customData: [:]
        )

        let token = try await fetchToken(for: userId)

        return (user, token.rawValue)
    }

    @MainActor
    static func fetchToken(
        for userId: String,
        callIds: [String] = []
    ) async throws -> UserToken {
        if
            AppEnvironment.configuration.isTest,
            AppEnvironment.contains(.mockJWT) {
            AppState.shared.apiKey = "hd8szvscpxvd"
            return fetchTestToken(for: userId)
        } else {
            let environment = {
                switch AppEnvironment.baseURL {
                case .staging:
                    return "pronto"
                case .pronto:
                    return "pronto"
                case .legacy:
                    return "pronto"
                case .demo:
                    return "demo"
                }
            }()

            var url = AppEnvironment
                .authBaseURL
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

            let (data, _) = try await URLSession.shared.data(from: url)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            let token = UserToken(rawValue: tokenResponse.token)
            AppState.shared.apiKey = tokenResponse.apiKey
            log.debug("Authentication info userId:\(tokenResponse.userId) apiKey:\(tokenResponse.apiKey) token:\(token)")
            return token
        }
    }

    static func fetchTestToken(
        for userId: String
    ) -> UserToken {
        TokenGenerator
            .shared
            .fetchToken(
                for: userId,
                expiration: AppEnvironment.value(for: .JWTExpiration).map { Int($0) ?? 100 } ?? 100
            )!
    }
}
