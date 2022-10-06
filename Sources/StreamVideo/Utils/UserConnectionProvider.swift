//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// The provider which can be used to provide a static token known on the client-side which doesn't expire.
    /// - Parameter token: The token to be returned by the token provider.
    /// - Returns: The new `TokenProvider` instance.
    static func `static`(_ token: Token) -> Self {
        .init { $0(.success(token)) }
    }
}
