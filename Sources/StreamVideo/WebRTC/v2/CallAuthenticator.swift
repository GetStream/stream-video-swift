//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallAuthenticating {

    func authenticate(
        create: Bool,
        ring: Bool,
        migratingFrom: String?
    ) async throws -> JoinCallResponse
}

final class CallAuthenticator: CallAuthenticating {

    typealias Authenticator = (Bool, Bool, String?) async throws -> JoinCallResponse

    private let authenticator: Authenticator

    init(
        _ authenticator: @escaping Authenticator
    ) {
        self.authenticator = authenticator
    }

    func authenticate(
        create: Bool,
        ring: Bool,
        migratingFrom: String?
    ) async throws -> JoinCallResponse {
        try await authenticator(create, ring, migratingFrom)
    }
}
