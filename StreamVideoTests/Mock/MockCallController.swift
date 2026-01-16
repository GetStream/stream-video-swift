//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallController: CallController, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case join
        case setDisconnectionTimeout
        case observeWebRTCStateUpdated
        case changeVideoState
        case enableClientCapabilities
        case disableClientCapabilities
    }

    enum MockFunctionInputKey: Payloadable {
        case setDisconnectionTimeout(timeout: TimeInterval)

        case join(
            create: Bool = true,
            callSettings: CallSettings?,
            options: CreateCallOptions?,
            ring: Bool = false,
            notify: Bool = false,
            source: JoinSource
        )

        case observeWebRTCStateUpdated

        case changeVideoState(Bool)

        case enableClientCapabilities(Set<ClientCapability>)

        case disableClientCapabilities(Set<ClientCapability>)

        var payload: Any {
            switch self {
            case let .setDisconnectionTimeout(timeout):
                return timeout
            case let .join(create, callSettings, options, ring, notify, source):
                return (create, callSettings, options, ring, notify, source)
            case .observeWebRTCStateUpdated:
                return ()
            case let .changeVideoState(value):
                return value
            case let .enableClientCapabilities(value):
                return value
            case let .disableClientCapabilities(value):
                return value
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    convenience init() {
        self.init(
            defaultAPI: MockDefaultAPIEndpoints(),
            user: .dummy(),
            callId: .unique,
            callType: .unique,
            apiKey: .unique,
            videoConfig: .dummy(),
            initialCallSettings: .default,
            cachedLocation: nil
        )
    }

    func stub<T>(for keyPath: KeyPath<MockCallController, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    override func joinCall(
        create: Bool = true,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        source: JoinSource
    ) async throws -> JoinCallResponse {
        stubbedFunctionInput[.join]?.append(
            .join(
                create: create,
                callSettings: callSettings,
                options: options,
                ring: ring,
                notify: notify,
                source: source
            )
        )

        if let stub = stubbedFunction[.join] as? JoinCallResponse {
            return stub
        } else if let joinError = stubbedFunction[.join] as? Error {
            throw joinError
        } else {
            return try await super.joinCall(
                create: create,
                callSettings: callSettings,
                options: options,
                ring: ring,
                notify: notify,
                source: source
            )
        }
    }

    override func setDisconnectionTimeout(_ timeout: TimeInterval) {
        stubbedFunctionInput[.setDisconnectionTimeout]?
            .append(.setDisconnectionTimeout(timeout: timeout))
    }

    override func observeWebRTCStateUpdated() {
        stubbedFunctionInput[.observeWebRTCStateUpdated]?
            .append(.observeWebRTCStateUpdated)
    }

    override func changeVideoState(isEnabled: Bool) async throws {
        stubbedFunctionInput[.changeVideoState]?
            .append(.changeVideoState(isEnabled))
    }

    override func enableClientCapabilities(
        _ capabilities: Set<ClientCapability>
    ) async {
        stubbedFunctionInput[.enableClientCapabilities]?
            .append(.enableClientCapabilities(capabilities))
    }

    override func disableClientCapabilities(
        _ capabilities: Set<ClientCapability>
    ) async {
        stubbedFunctionInput[.disableClientCapabilities]?
            .append(.disableClientCapabilities(capabilities))
    }
}
