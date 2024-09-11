//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketClient: WebSocketClient, Mockable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
    }

    enum FunctionInput: Payloadable {
        case disconnect(
            code: URLSessionWebSocketTask.CloseCode,
            source: WebSocketConnectionState.DisconnectionSource,
            completion: () -> Void
        )

        var payload: Any {
            switch self {
            case let .disconnect(code, source, completion):
                return (code, source, completion)
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInput]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInput]]()) { $0[$1] = [] }

    let mockEngine: MockWebSocketEngine = .init()
    var stubbedFunction: [FunctionKey: Any] = [:]
    private(set) var timesFunctionWasCalled: [FunctionKey: Int] = [:]

    func stub<T>(for keyPath: KeyPath<MockWebSocketClient, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

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
        if let value = timesFunctionWasCalled[.connect] {
            timesFunctionWasCalled[.connect] = value + 1
        } else {
            timesFunctionWasCalled[.connect] = 1
        }
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
        
        if let value = timesFunctionWasCalled[.disconnect] {
            timesFunctionWasCalled[.disconnect] = value + 1
        } else {
            timesFunctionWasCalled[.disconnect] = 1
        }

        completion()
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
