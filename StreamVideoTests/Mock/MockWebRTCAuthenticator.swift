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
            create: Bool,
            ring: Bool,
            notify: Bool,
            options: CreateCallOptions?
        )

        case waitForAuthentication(sfuAdapter: SFUAdapter)
        case waitForConnect(sfuAdapter: SFUAdapter)

        var payload: Any {
            switch self {
            case let .authenticate(coordinator, currentSFU, create, ring, notify, options):
                return (coordinator, currentSFU, create, ring, notify, options)
            case let .waitForAuthentication(sfuAdapter):
                return sfuAdapter
            case let .waitForConnect(sfuAdapter):
                return sfuAdapter
            }
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
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse) {
        stubbedFunctionInput[.authenticate]?
            .append(
                .authenticate(
                    coordinator: coordinator,
                    currentSFU: currentSFU,
                    create: create,
                    ring: ring,
                    notify: notify,
                    options: options
                )
            )

        switch stubbedFunction[.authenticate] as? Result<(SFUAdapter, JoinCallResponse), Error> {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
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
