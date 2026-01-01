//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallAuthenticator: @unchecked Sendable {

    var authenticateResult: Result<JoinCallResponse, Error> = .failure(ClientError.Unknown())

    private(set) var authenticateCalledWithInput: [(
        create: Bool,
        ring: Bool,
        migratingFrom: String?,
        notify: Bool,
        options: CreateCallOptions?
    )] = []

    func authenticate(
        create: Bool,
        ring: Bool,
        migratingFrom: String?,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> JoinCallResponse {
        authenticateCalledWithInput.append(
            (
                create,
                ring,
                migratingFrom,
                notify,
                options
            )
        )
        switch authenticateResult {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        }
    }
}
