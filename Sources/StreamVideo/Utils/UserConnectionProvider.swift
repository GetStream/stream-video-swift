//
//  UserConnectionProvider.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 19.7.22.
//

import Foundation

/// The type designed to provider a `Token` to the `ChatClient` when it asks for it.
struct UserConnectionProvider {
    let tokenProvider: TokenProvider
}

extension UserConnectionProvider {
    /// The provider that can be used when user is unknown.
    static var anonymous: Self {
        .static(.anonymous)
    }

    /// The provider that can be used during the development. It's handy since doesn't require a token.
    /// - Parameter userId: The user identifier.
    /// - Returns: The new `TokenProvider` instance.
    static func development(userId: String) -> Self {
        .static(.development(userId: userId))
    }

    /// The provider which can be used to provide a static token known on the client-side which doesn't expire.
    /// - Parameter token: The token to be returned by the token provider.
    /// - Returns: The new `TokenProvider` instance.
    static func `static`(_ token: Token) -> Self {
        .init { $0(.success(token)) }
    }

}
