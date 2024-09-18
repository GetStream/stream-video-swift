//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallAuthenticator {

    var authenticateResult: Result<JoinCallResponse, Error> = .failure(ClientError.Unknown())

    private(set) var authenticateCalledWithInput: [(create: Bool, ring: Bool, migratingFrom: String?)] = []

    func authenticate(
        create: Bool,
        ring: Bool,
        migratingFrom: String?
    ) async throws -> JoinCallResponse {
        authenticateCalledWithInput.append((create, ring, migratingFrom))
        switch authenticateResult {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        }
    }
}
