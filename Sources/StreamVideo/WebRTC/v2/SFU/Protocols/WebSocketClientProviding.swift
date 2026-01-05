//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol defining methods for creating WebSocket clients.
protocol WebSocketClientProviding {

    /// Builds and returns a WebSocket client with the specified parameters.
    /// - Parameters:
    ///   - sessionConfiguration: The URL session configuration.
    ///   - eventDecoder: The decoder for parsing events.
    ///   - eventNotificationCenter: The notification center for events.
    ///   - webSocketClientType: The type of WebSocket client.
    ///   - environment: The environment for the WebSocket client.
    ///   - connectURL: The URL to connect to.
    ///   - requiresAuth: Whether authentication is required.
    /// - Returns: A configured WebSocketClient instance.
    func build(
        sessionConfiguration: URLSessionConfiguration,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        webSocketClientType: WebSocketClientType,
        environment: WebSocketClient.Environment,
        connectURL: URL,
        requiresAuth: Bool
    ) -> WebSocketClient
}

/// A concrete implementation of `WebSocketClientProviding`.
final class WebSocketClientFactory: WebSocketClientProviding {

    /// Builds and returns a WebSocket client with the specified parameters.
    /// - Parameters:
    ///   - sessionConfiguration: The URL session configuration.
    ///   - eventDecoder: The decoder for parsing events.
    ///   - eventNotificationCenter: The notification center for events.
    ///   - webSocketClientType: The type of WebSocket client.
    ///   - environment: The environment for the WebSocket client.
    ///     Defaults to a new instance.
    ///   - connectURL: The URL to connect to.
    ///   - requiresAuth: Whether authentication is required. Defaults to true.
    /// - Returns: A configured WebSocketClient instance.
    func build(
        sessionConfiguration: URLSessionConfiguration,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        webSocketClientType: WebSocketClientType,
        environment: WebSocketClient.Environment = .init(),
        connectURL: URL,
        requiresAuth: Bool = true
    ) -> WebSocketClient {
        .init(
            sessionConfiguration: sessionConfiguration,
            eventDecoder: eventDecoder,
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: webSocketClientType,
            environment: environment,
            connectURL: connectURL,
            requiresAuth: requiresAuth
        )
    }
}
