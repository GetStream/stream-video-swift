//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo

final class MockCoordinatorWebSocket: CoordinatorWebSocketProtocol, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
    }

    enum FunctionInput: Payloadable {
        case connect
        case disconnect(source: WebSocketConnectionState.DisconnectionSource)

        var payload: Any {
            switch self {
            case .connect:
                return ()
            case let .disconnect(source):
                return source
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    var stubbedFunctionInput: [FunctionKey: [FunctionInput]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInput]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockCoordinatorWebSocket, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - CoordinatorWebSocketProtocol

    @Published var connectionStateValue: WebSocketConnectionState = .initialized
    var connectionState: WebSocketConnectionState { connectionStateValue }
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        $connectionStateValue.eraseToAnyPublisher()
    }

    func connect() {
        stubbedFunctionInput[.connect]?.append(.connect)
    }

    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        completion: @Sendable @escaping () -> Void
    ) {
        stubbedFunctionInput[.disconnect]?.append(.disconnect(source: source))
        completion()
    }

    // MARK: - Helpers

    func simulate(state: WebSocketConnectionState) {
        connectionStateValue = state
    }
}
