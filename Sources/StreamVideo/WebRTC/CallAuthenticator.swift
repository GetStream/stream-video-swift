//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallAuthenticating {

    func authenticate(create: Bool) async throws -> JoinCallResponse
}

final class CallAuthenticator: CallAuthenticating {

    typealias Authenticator = (Bool) async throws -> JoinCallResponse

    private let authenticator: Authenticator

    init(
        _ authenticator: @escaping Authenticator
    ) {
        self.authenticator = authenticator
    }

    func authenticate(create: Bool) async throws -> JoinCallResponse {
        try await authenticator(create)
    }
}
