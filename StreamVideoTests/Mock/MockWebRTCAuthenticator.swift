//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockWebRTCAuthenticator: WebRTCAuthenticating, Mockable, @unchecked Sendable {
    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    enum MockFunctionKey: CaseIterable { case authenticate, waitForAuthentication, waitForConnect }
    enum MockFunctionInputKey: Payloadable {
        case authenticate(
            coordinator: WebRTCCoordinator,
            currentSFU: String?,
            migratingFromList: [String]?,
            create: Bool,
            ring: Bool,
            notify: Bool,
            options: CreateCallOptions?,
            declaresPlaybackCapabilities: Bool
        )

        case waitForAuthentication(sfuAdapter: SFUAdapter)
        case waitForConnect(sfuAdapter: SFUAdapter)

        var payload: Any {
            switch self {
            case let .authenticate(
                coordinator,
                currentSFU,
                migratingFromList,
                create,
                ring,
                notify,
                options,
                declaresPlaybackCapabilities
            ):
                return (
                    coordinator,
                    currentSFU,
                    migratingFromList,
                    create,
                    ring,
                    notify,
                    options,
                    declaresPlaybackCapabilities
                )
            case let .waitForAuthentication(sfuAdapter):
                return sfuAdapter
            case let .waitForConnect(sfuAdapter):
                return sfuAdapter
            }
        }
    }

    /// Called (and awaited) at the start of ``authenticate``.
    /// Set to a suspending closure to block the mock until the
    /// test is ready, preventing the connecting stage from racing.
    var onAuthenticate: (@Sendable () async throws -> Void)?

    /// The `declaresPlaybackCapabilities` value of each ``authenticate`` call.
    var declaredPlaybackCapabilities: [Bool] {
        (stubbedFunctionInput[.authenticate] ?? []).compactMap {
            guard case let .authenticate(_, _, _, _, _, _, _, declared) = $0 else {
                return nil
            }
            return declared
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockWebRTCAuthenticator, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    init() {
        stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>.failure(ClientError())
        )

        stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.failure(ClientError())
        )

        stub(
            for: .waitForConnect,
            with: Result<Void, Error>.failure(ClientError())
        )
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        migratingFromList: [String]?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?,
        declaresPlaybackCapabilities: Bool
    ) async throws -> (sfuAdapter: SFUAdapter?, response: JoinCallResponse) {
        stubbedFunctionInput[.authenticate]?
            .append(
                .authenticate(
                    coordinator: coordinator,
                    currentSFU: currentSFU,
                    migratingFromList: migratingFromList,
                    create: create,
                    ring: ring,
                    notify: notify,
                    options: options,
                    declaresPlaybackCapabilities: declaresPlaybackCapabilities
                )
            )

        try await onAuthenticate?()

        // An HLS grant has no SFU adapter, so it is stubbed with an optional.
        switch stubbedFunction[.authenticate] {
        case let result as Result<(SFUAdapter, JoinCallResponse), Error>:
            return try result.get()
        case let result as Result<(SFUAdapter?, JoinCallResponse), Error>:
            return try result.get()
        default:
            throw ClientError("Not stubbed function.")
        }
    }

    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws {
        stubbedFunctionInput[.waitForAuthentication]?
            .append(.waitForAuthentication(sfuAdapter: sfuAdapter))

        switch stubbedFunction[.waitForAuthentication] as? Result<Void, Error> {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        default:
            break
        }
    }

    func waitForConnect(on sfuAdapter: SFUAdapter) async throws {
        stubbedFunctionInput[.waitForConnect]?
            .append(.waitForConnect(sfuAdapter: sfuAdapter))

        switch stubbedFunction[.waitForConnect] as? Result<Void, Error> {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        default:
            break
        }
    }
}
