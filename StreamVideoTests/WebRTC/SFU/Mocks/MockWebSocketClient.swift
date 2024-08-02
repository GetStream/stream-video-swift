//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketClient: WebSocketClient, Mockable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable {
        case connect
        case disconnect
    }

    var stubbedProperty: [String: Any] = [:]

    let mockEngine: MockWebSocketEngine = .init()
    var stubbedFunction: [FunctionKey: Any] = [:]
    private(set) var timesFunctionWasCalled: [FunctionKey: Int] = [:]
    private(set) var updatePausedWasCalled: Bool?

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
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        if let value = timesFunctionWasCalled[.disconnect] {
            timesFunctionWasCalled[.disconnect] = value + 1
        } else {
            timesFunctionWasCalled[.disconnect] = 1
        }
    }

    override func updatePaused(_ isPaused: Bool) {
        updatePausedWasCalled = isPaused
    }
}
