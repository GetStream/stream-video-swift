//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketClient: WebSocketClient, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
        case disconnectAsync
    }

    enum FunctionInput: Payloadable {
        case connect
        case disconnect(
            code: URLSessionWebSocketTask.CloseCode,
            source: WebSocketConnectionState.DisconnectionSource,
            completion: () -> Void
        )
        case disconnectAsync(source: WebSocketConnectionState.DisconnectionSource)

        var payload: Any {
            switch self {
            case .connect:
                return ()
            case let .disconnect(code, source, completion):
                return (code, source, completion)
            case let .disconnectAsync(source):
                return source
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInput]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInput]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockWebSocketClient, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - Super

    let mockEngine: MockWebSocketEngine = .init()
    override var engine: (any WebSocketEngine)? {
        get { self[dynamicMember: \.engine] }
        set { _ = newValue }
    }

    convenience init(webSocketClientType: WebSocketClientType) {
        self.init(
            sessionConfiguration: .default,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: .init(),
            webSocketClientType: webSocketClientType,
            connectURL: .init(string: "https://getstream.io")!
        )
        stub(for: \.engine, with: mockEngine)
    }

    override func connect() {
        stubbedFunctionInput[.connect]?.append(.connect)
    }

    override func disconnect(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        stubbedFunctionInput[.disconnect]?.append(
            .disconnect(
                code: code,
                source: source,
                completion: completion
            )
        )
        completion()
    }

    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated
    ) async {
        stubbedFunctionInput[.disconnectAsync]?.append(
            .disconnectAsync(source: source)
        )
    }

    // MARK: - Helpers

    func simulate(state: WebSocketConnectionState) {
        stub(for: \.connectionState, with: state)
        connectionStateDelegate?.webSocketClient(
            self,
            didUpdateConnectionState: state
        )
    }
}
