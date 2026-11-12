//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallAuthenticator: @unchecked Sendable {

    typealias AuthenticateHandler = (
        Bool,
        Bool,
        String?,
        [String]?,
        Bool,
        CreateCallOptions?,
        Bool
    ) async throws -> JoinCallResponse

    var authenticateResult: Result<JoinCallResponse, Error> = .failure(ClientError.Unknown())
    var authenticateHandler: AuthenticateHandler?

    private(set) var authenticateCalledWithInput: [(
        create: Bool,
        ring: Bool,
        migratingFrom: String?,
        migratingFromList: [String]?,
        notify: Bool,
        options: CreateCallOptions?,
        declaresPlaybackCapabilities: Bool
    )] = []

    func authenticate(
        create: Bool,
        ring: Bool,
        migratingFrom: String?,
        migratingFromList: [String]?,
        notify: Bool,
        options: CreateCallOptions?,
        declaresPlaybackCapabilities: Bool
    ) async throws -> JoinCallResponse {
        authenticateCalledWithInput.append(
            (
                create,
                ring,
                migratingFrom,
                migratingFromList,
                notify,
                options,
                declaresPlaybackCapabilities
            )
        )
        if let authenticateHandler {
            return try await authenticateHandler(
                create,
                ring,
                migratingFrom,
                migratingFromList,
                notify,
                options,
                declaresPlaybackCapabilities
            )
        }
        switch authenticateResult {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        }
    }
}
