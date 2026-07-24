//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore

/// Owns the coordinator signaling WebSocket, backed by `WebSocketClient`.
///
/// It decodes coordinator events through the shared notification center and
/// sends StreamVideo's authentication payload when the connection opens.
final class CoordinatorWebSocket:
    ConnectionStateDelegate,
    @unchecked Sendable {

    private let webSocket: WebSocketClient
    /// Builds the connect payload (video's `WSAuthMessageRequest`) sent once the
    /// socket connects. Provided by the caller since it needs the current
    /// user/token; returns `nil` if the caller is gone.
    private let connectPayloadProvider: () -> (any Codable)?
    private let recoveryHandler: ConnectionRecoveryHandler

    var connectionState: WebSocketConnectionState { webSocket.connectionState }

    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        webSocket.connectionStatePublisher
    }

    init(
        url: URL,
        eventNotificationCenter: EventNotificationCenter,
        sessionConfiguration: URLSessionConfiguration = .default,
        connectPayloadProvider: @escaping () -> (any Codable)?,
        hasActiveCall: @escaping @Sendable () -> Bool
    ) {
        self.connectPayloadProvider = connectPayloadProvider

        let webSocket = WebSocketClient(
            sessionConfiguration: sessionConfiguration,
            eventDecoder: JsonEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .coordinator,
            connectRequest: URLRequest(url: url),
            healthCheckBeforeConnected: true,
            requiresAuth: true,
            pingInterval: 5
        )
        self.webSocket = webSocket

        // StreamCore's recovery handler drives reconnection off the underlying
        // client. Compose its policies with the video-specific CallKit policy:
        // internet AND wsAuto AND (background OR CallKit).
        let backgroundTaskScheduler = Self.makeBackgroundTaskScheduler()
        let internetConnection = InternetConnection(
            monitor: InternetConnection.Monitor()
        )
        recoveryHandler = DefaultConnectionRecoveryHandler(
            webSocketClient: webSocket,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: backgroundTaskScheduler,
            internetConnection: internetConnection,
            reconnectionStrategy: DefaultRetryStrategy(),
            reconnectionTimerType: DefaultTimer.self,
            keepConnectionAliveInBackground: true,
            reconnectionPolicies: [
                WebSocketAutomaticReconnectionPolicy(webSocket),
                InternetAvailabilityReconnectionPolicy(internetConnection),
                CompositeReconnectionPolicy(.or, policies: [
                    BackgroundStateReconnectionPolicy(backgroundTaskScheduler),
                    CallKitReconnectionPolicy(hasActiveCall: hasActiveCall)
                ])
            ]
        )

        webSocket.connectionStateDelegate = self
        webSocket.onWSConnectionEstablished = { [weak self] in
            guard let self, let payload = self.connectPayloadProvider() else { return }
            self.webSocket.engine?.send(jsonMessage: payload)
        }
    }

    private static func makeBackgroundTaskScheduler() -> BackgroundTaskScheduler? {
        guard !Bundle.main.isAppExtension else { return nil }
        #if os(iOS)
        return IOSBackgroundTaskScheduler()
        #else
        return nil
        #endif
    }

    func connect() {
        webSocket.connect()
    }

    func disconnect() async {
        await webSocket.disconnect()
    }

    // MARK: - ConnectionStateDelegate

    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        if case let .disconnected(source) = state,
           let serverError = source.serverError,
           serverError.isInvalidTokenError || serverError.isTokenExpiredError {
            // StreamVideo refreshes the token from the state publisher and
            // reconnects explicitly. Do not let Core reconnect with the stale
            // token in parallel.
            return
        }

        recoveryHandler.webSocketClient(
            client,
            didUpdateConnectionState: state
        )
    }
}
