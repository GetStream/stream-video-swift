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
    /// The current connection state (video's `WebSocketConnectionState`, mapped
    /// from StreamCore's at the boundary).
    var connectionState: VideoWebSocketConnectionState { get }
    /// Emits every connection-state change.
    var connectionStatePublisher: AnyPublisher<VideoWebSocketConnectionState, Never> { get }

    func connect()
    func disconnect(
        source: VideoWebSocketConnectionState.DisconnectionSource,
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
/// - maps `StreamCore.WebSocketConnectionState` back into video's
///   `WebSocketConnectionState`.
///
/// - TODO: [IOS-1812] Remove this isolation wrapper and its `Video*` aliases
///   after the remaining connection and error types are unified.
final class CoordinatorWebSocket:
    CoordinatorWebSocketProtocol,
    StreamCore.ConnectionStateDelegate,
    @unchecked Sendable {

    private let webSocket: StreamCore.WebSocketClient
    /// Builds the connect payload (video's `WSAuthMessageRequest`) sent once the
    /// socket connects. Provided by the caller since it needs the current
    /// user/token; returns `nil` if the caller is gone.
    private let connectPayloadProvider: () -> (any Codable)?
    /// StreamCore's recovery handler, owned here so reconnection stays inside the
    /// StreamCore boundary. Receives state forwarded from this wrapper.
    private let recoveryHandler: StreamCore.ConnectionRecoveryHandler

    @Published private(set) var connectionState: VideoWebSocketConnectionState = .initialized
    var connectionStatePublisher: AnyPublisher<VideoWebSocketConnectionState, Never> {
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

        let webSocket = StreamCore.WebSocketClient(
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
        recoveryHandler = StreamCore.DefaultConnectionRecoveryHandler(
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

    private static func makeBackgroundTaskScheduler() -> StreamCore.BackgroundTaskScheduler? {
        guard !Bundle.main.isAppExtension else { return nil }
        #if os(iOS)
        return StreamCore.IOSBackgroundTaskScheduler()
        #else
        return nil
        #endif
    }

    func connect() {
        webSocket.connect()
    }

    func disconnect(
        source: VideoWebSocketConnectionState.DisconnectionSource,
        completion: @Sendable @escaping () -> Void
    ) {
        webSocket.disconnect(
            code: .normalClosure,
            source: .init(source),
            completion: completion
        )
    }

    // MARK: - ConnectionStateDelegate

    func webSocketClient(
        _ client: StreamCore.WebSocketClient,
        didUpdateConnectionState state: StreamCore.WebSocketConnectionState
    ) {
        connectionState = .init(state)
        // Forward the raw state to the recovery handler (it's a
        // ConnectionStateDelegate but not the socket's delegate — we are).
        recoveryHandler.webSocketClient(client, didUpdateConnectionState: state)
    }
}

extension VideoWebSocketConnectionState {
    /// Maps StreamCore's connection state into video's.
    init(_ state: StreamCore.WebSocketConnectionState) {
        switch state {
        case .initialized:
            self = .initialized
        case .connecting:
            self = .connecting
        case .authenticating:
            self = .authenticating
        case let .connected(healthCheckInfo):
            self = .connected(
                healthCheckInfo: VideoHealthCheckInfo(
                    coordinatorHealthCheck: healthCheckInfo.connectionId.map {
                        HealthCheckEvent(connectionId: $0, createdAt: Date())
                    },
                    sfuHealthCheck: nil
                )
            )
        case let .disconnecting(source):
            self = .disconnecting(source: .init(source))
        case let .disconnected(source):
            self = .disconnected(source: .init(source))
        @unknown default:
            self = .disconnected(source: .systemInitiated)
        }
    }
}

extension VideoWebSocketConnectionState.DisconnectionSource {
    /// Maps StreamCore's disconnection source into video's.
    ///
    /// For `serverInitiated`, the StreamCore error's `apiError` (if any) is
    /// carried through so video's `ClientError.isInvalidTokenError` /
    /// `apiError` gating keeps working; otherwise the whole error is stored as
    /// the underlying error. StreamCore's `.timeout` has no video equivalent, so
    /// it maps to `.systemInitiated`.
    init(_ source: StreamCore.WebSocketConnectionState.DisconnectionSource) {
        switch source {
        case .userInitiated:
            self = .userInitiated
        case .systemInitiated:
            self = .systemInitiated
        case .noPongReceived:
            self = .noPongReceived
        case let .serverInitiated(error):
            self = .serverInitiated(error: error.map { VideoClientError(with: $0.apiError ?? $0) })
        case .timeout:
            self = .systemInitiated
        @unknown default:
            self = .systemInitiated
        }
    }
}

extension StreamCore.WebSocketConnectionState.DisconnectionSource {
    /// Maps video's (outbound) disconnection source into StreamCore's. Used when
    /// video code asks the wrapper to disconnect.
    init(_ source: VideoWebSocketConnectionState.DisconnectionSource) {
        switch source {
        case .userInitiated:
            self = .userInitiated
        case .systemInitiated:
            self = .systemInitiated
        case .noPongReceived:
            self = .noPongReceived
        case .serverInitiated:
            self = .serverInitiated(error: nil)
        }
    }
}
