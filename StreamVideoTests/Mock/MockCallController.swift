//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallController: CallController, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case join
        case leave
        case setDisconnectionTimeout
        case observeWebRTCStateUpdated
        case changeAudioState
        case changeVideoState
        case changeCameraMode
        case updateOwnCapabilities
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
            source: JoinSource,
            policy: WebRTCJoinPolicy
        )

        case leave(reason: String?)

        case observeWebRTCStateUpdated

        case changeAudioState(Bool)

        case changeVideoState(Bool)

        case changeCameraMode(CameraPosition)

        case updateOwnCapabilities([OwnCapability])

        case enableClientCapabilities(Set<ClientCapability>)

        case disableClientCapabilities(Set<ClientCapability>)

        var payload: Any {
            switch self {
            case let .setDisconnectionTimeout(timeout):
                return timeout
            case let .join(
                create,
                callSettings,
                options,
                ring,
                notify,
                source,
                policy
            ):
                return (create, callSettings, options, ring, notify, source, policy)
            case let .leave(reason):
                return reason ?? ""
            case .observeWebRTCStateUpdated:
                return ()
            case let .changeAudioState(value):
                return value
            case let .changeVideoState(value):
                return value
            case let .changeCameraMode(value):
                return value
            case let .updateOwnCapabilities(value):
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
        source: JoinSource,
        policy: WebRTCJoinPolicy = .default
    ) async throws -> JoinCallResponse {
        stubbedFunctionInput[.join]?.append(
            .join(
                create: create,
                callSettings: callSettings,
                options: options,
                ring: ring,
                notify: notify,
                source: source,
                policy: policy
            )
        )

        if let callSettings {
            await call?.state.update(callSettings: callSettings)
        }

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
                source: source,
                policy: policy
            )
        }
    }

    override func setDisconnectionTimeout(_ timeout: TimeInterval) {
        stubbedFunctionInput[.setDisconnectionTimeout]?
            .append(.setDisconnectionTimeout(timeout: timeout))
    }

    override func leave(reason: String?) {
        stubbedFunctionInput[.leave]?
            .append(.leave(reason: reason))
    }

    override func observeWebRTCStateUpdated() {
        stubbedFunctionInput[.observeWebRTCStateUpdated]?
            .append(.observeWebRTCStateUpdated)
    }

    override func changeVideoState(isEnabled: Bool) async throws {
        stubbedFunctionInput[.changeVideoState]?
            .append(.changeVideoState(isEnabled))
    }

    override func changeAudioState(
        isEnabled: Bool,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws {
        stubbedFunctionInput[.changeAudioState]?
            .append(.changeAudioState(isEnabled))
    }

    override func changeCameraMode(position: CameraPosition) async throws {
        stubbedFunctionInput[.changeCameraMode]?
            .append(.changeCameraMode(position))
    }

    override func updateOwnCapabilities(ownCapabilities: [OwnCapability]) async {
        stubbedFunctionInput[.updateOwnCapabilities]?
            .append(.updateOwnCapabilities(ownCapabilities))
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
