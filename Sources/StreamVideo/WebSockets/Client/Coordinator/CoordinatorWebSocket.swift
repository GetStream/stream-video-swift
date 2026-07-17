//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore

/// The surface `StreamVideo` depends on for the coordinator signaling socket.
///
/// Extracted so the coordinator client can be tested with a mock while
/// production uses ``CoordinatorWebSocket`` (backed by
/// `StreamCore.WebSocketClient`).
protocol CoordinatorWebSocketProtocol: AnyObject {
    /// The current connection state.
    var connectionState: WebSocketConnectionState { get }
    /// Emits every connection-state change.
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> { get }

    func connect()
    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        completion: @Sendable @escaping () -> Void
    )
}

extension CoordinatorWebSocketProtocol {
    /// Convenience user-initiated disconnect.
    func disconnect(completion: @Sendable @escaping () -> Void) {
        disconnect(source: .userInitiated, completion: completion)
    }
}

/// Owns the coordinator signaling WebSocket, backed by `StreamCore.WebSocketClient`.
///
/// This is the single boundary that imports StreamCore for the coordinator
/// socket. It:
/// - decodes coordinator events via ``JsonEventDecoder`` through the shared
///   app event notification center;
/// - performs the auth handshake by sending video's connect payload on
///   `onWSConnectionEstablished`;
final class CoordinatorWebSocket:
    CoordinatorWebSocketProtocol,
    ConnectionStateDelegate,
    @unchecked Sendable {

    private let webSocket: WebSocketClient
    /// Builds the connect payload (video's `WSAuthMessageRequest`) sent once the
    /// socket connects. Provided by the caller since it needs the current
    /// user/token; returns `nil` if the caller is gone.
    private let connectPayloadProvider: () -> (any Codable)?
    /// StreamCore's recovery handler, owned here so reconnection stays inside the
    /// StreamCore boundary. Receives state forwarded from this wrapper.
    private let recoveryHandler: ConnectionRecoveryHandler

    @Published private(set) var connectionState: WebSocketConnectionState = .initialized
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        $connectionState.eraseToAnyPublisher()
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
            requiresAuth: true,
            // Coordinator keep-alive is a native WS ping (handled by StreamCore's
            // ping controller), not an app-level message — so no builder.
            pingRequestBuilder: nil
        )
        self.webSocket = webSocket

        // StreamCore's recovery handler drives reconnection off the underlying
        // client. Compose its policies with the video-specific CallKit policy:
        // internet AND wsAuto AND (background OR CallKit).
        let backgroundTaskScheduler = Self.makeBackgroundTaskScheduler()
        let internetConnection = StreamCore.InternetConnection(
            monitor: StreamCore.InternetConnection.Monitor()
        )
        recoveryHandler = DefaultConnectionRecoveryHandler(
            webSocketClient: webSocket,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: backgroundTaskScheduler,
            internetConnection: internetConnection,
            reconnectionStrategy: StreamCore.DefaultRetryStrategy(),
            reconnectionTimerType: StreamCore.DefaultTimer.self,
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
            webSocket.engine?.send(jsonMessage: payload)
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

    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        completion: @Sendable @escaping () -> Void
    ) {
        webSocket.disconnect(
            code: .normalClosure,
            source: source,
            completion: completion
        )
    }

    // MARK: - ConnectionStateDelegate

    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        connectionState = state
        // Forward the raw state to the recovery handler (it's a
        // ConnectionStateDelegate but not the socket's delegate — we are).
        recoveryHandler.webSocketClient(client, didUpdateConnectionState: state)
    }
}
