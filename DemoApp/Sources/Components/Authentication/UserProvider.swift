//
//  UserProvider.swift
//  StreamVideoCallCore
//
//  Created by Ilias Pavlidakis on 2/6/23.
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
            .appending(URLQueryItem(name: "api_key", value: AppEnvironment.apiKey))

        let (data, _) = try await URLSession.shared.data(from: url)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let token = UserToken(rawValue: tokenResponse.token)
        return (user, token.rawValue)
    }
}
