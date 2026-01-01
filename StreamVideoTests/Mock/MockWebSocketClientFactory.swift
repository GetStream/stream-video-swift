//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockWebSocketClientFactory: WebSocketClientProviding, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    enum MockFunctionKey: CaseIterable { case build }
    enum MockFunctionInputKey: Payloadable {
        case build(
            sessionConfiguration: URLSessionConfiguration,
            eventDecoder: any AnyEventDecoder,
            eventNotificationCenter: EventNotificationCenter,
            webSocketClientType: WebSocketClientType,
            environment: WebSocketClient.Environment,
            connectURL: URL,
            requiresAuth: Bool
        )

        var payload: Any {
            switch self {
            case let .build(
                sessionConfiguration,
                eventDecoder,
                eventNotificationCenter,
                webSocketClientType,
                environment,
                connectURL,
                requiresAuth
            ):
                return (
                    sessionConfiguration,
                    eventDecoder,
                    eventNotificationCenter,
                    webSocketClientType,
                    environment,
                    connectURL,
                    requiresAuth
                )
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockWebSocketClientFactory, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    init() {
        stub(for: .build, with: MockWebSocketClient(webSocketClientType: .sfu))
    }

    // MARK: - WebSocketClientProviding

    func build(
        sessionConfiguration: URLSessionConfiguration,
        eventDecoder: any AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        webSocketClientType: WebSocketClientType,
        environment: WebSocketClient.Environment,
        connectURL: URL,
        requiresAuth: Bool
    ) -> WebSocketClient {
        stubbedFunctionInput[.build]?
            .append(
                .build(
                    sessionConfiguration: sessionConfiguration,
                    eventDecoder: eventDecoder,
                    eventNotificationCenter: eventNotificationCenter,
                    webSocketClientType: webSocketClientType,
                    environment: environment,
                    connectURL: connectURL,
                    requiresAuth: requiresAuth
                )
            )
        return stubbedFunction[.build] as! WebSocketClient
    }
}
