//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum TokenProvider {

    static func fetchToken(
        for userId: String,
        callIds: [String] = []
    ) async throws -> UserToken {
        if 
            AppEnvironment.configuration.isTest,
            AppEnvironment.contains(.mockJWT) {
            return fetchTestToken(for: userId)
        } else {
            var url = AppEnvironment
                .authBaseURL
                .appendingPathComponent("api")
                .appendingPathComponent("auth")
                .appendingPathComponent("create-token")
                .appending(URLQueryItem(name: "api_key", value: AppEnvironment.apiKey.rawValue))
                .appending(URLQueryItem(name: "user_id", value: userId))

            if !callIds.isEmpty {
                url = url.appending(URLQueryItem(name: "call_cids", value: callIds.joined(separator: ",")))
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            let token = UserToken(rawValue: tokenResponse.token)
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
