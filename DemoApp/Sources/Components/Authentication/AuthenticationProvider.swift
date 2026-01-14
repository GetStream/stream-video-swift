//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        if case let .custom(_, apiKey, token) = AppEnvironment.baseURL {
            log.debug("Authentication info userId:\(userId) apiKey:\(apiKey) token:\(token)")
            return .init(stringLiteral: token)
        }

        let environment = {
            switch AppEnvironment.baseURL {
            case .staging:
                return "pronto"
            case .pronto:
                return "pronto"
            case .prontoStaging:
                return "pronto-staging"
            case .legacy:
                return "pronto"
            case .demo:
                return "demo"
            case .prontoFrankfurtC1:
                return "pronto-fra-c1"
            case .prontoFrankfurtC2:
                return "pronto-fra-c2"
            case .livestream:
                return "demo"
            case .custom:
                return ""
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

        if AppEnvironment.configuration.isTest {
            if AppEnvironment.contains(.invalidateJWT) {
                AppEnvironment.tokenExpiration = .custom(2) // set to 2 seconds
            } else if
                let forcedExpirationString = AppEnvironment.value(for: .JWTExpiration),
                let forcedExpiration = Int(forcedExpirationString) {
                AppEnvironment.tokenExpiration = .custom(forcedExpiration)
            }
        }

        switch AppEnvironment.tokenExpiration {
        case .never:
            break
        default:
            url = url.appending(
                URLQueryItem(
                    name: "exp",
                    value: "\(AppEnvironment.tokenExpiration.interval)"
                )
            )
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        AppState.shared.apiKey = tokenResponse.apiKey
        let token = {
            if
                AppEnvironment.configuration.isTest,
                AppEnvironment.contains(.breakJWT) {
                return UserToken(rawValue: "")
            } else {
                return UserToken(rawValue: tokenResponse.token)
            }
        }()
        log.debug("Authentication response: \(tokenResponse)")
        return token
    }
}
