//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockCallController: CallController, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case join
        case setDisconnectionTimeout
        case observeWebRTCStateUpdated
    }

    enum MockFunctionInputKey: Payloadable {
        case setDisconnectionTimeout(timeout: TimeInterval)

        case join(
            create: Bool = true,
            callSettings: CallSettings?,
            options: CreateCallOptions?,
            ring: Bool = false,
            notify: Bool = false
        )

        case observeWebRTCStateUpdated

        var payload: Any {
            switch self {
            case let .setDisconnectionTimeout(timeout):
                return timeout
            case let .join(create, callSettings, options, ring, notify):
                return (create, callSettings, options, ring, notify)
            case .observeWebRTCStateUpdated:
                return ()
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
            defaultAPI: .dummy(),
            user: .dummy(),
            callId: .unique,
            callType: .unique,
            apiKey: .unique,
            videoConfig: .dummy(),
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
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        stubbedFunctionInput[.join]?.append(
            .join(
                create: create,
                callSettings: callSettings,
                options: options,
                ring: ring,
                notify: notify
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
                notify: notify
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
}
