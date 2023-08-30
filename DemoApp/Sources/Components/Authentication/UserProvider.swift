//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum UserProvider {

    static func createUser() async throws -> (User, String) {
        let userId = String(String.unique.prefix(8))
        let user = User(
            id: userId,
            name: userId,
            imageURL: nil,
            customData: [:]
        )
        let url = AppEnvironment.authBaseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("create-token")
            .appending(URLQueryItem(name: "user_id", value: userId))
            .appending(URLQueryItem(name: "api_key", value: AppEnvironment.apiKey.rawValue))

        let (data, _) = try await URLSession.shared.data(from: url)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let token = UserToken(rawValue: tokenResponse.token)
        return (user, token.rawValue)
    }
}
