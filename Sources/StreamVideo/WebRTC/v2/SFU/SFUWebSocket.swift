//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore

/// The surface `SFUAdapter` depends on for the SFU signaling WebSocket.
///
/// Extracted so `SFUAdapter` can be tested with a mock while production uses
/// `SFUWebSocket` (backed by `StreamCore.WebSocketClient`).
protocol SFUWebSocketProtocol: AnyObject {
    /// The URL used for the WebSocket connection.
    var connectURL: URL { get }
    /// The current connection state.
    var connectionState: SFUConnectionState { get }
    /// Emits every connection-state change.
    var connectionStatePublisher: AnyPublisher<SFUConnectionState, Never> { get }
    /// Emits every inbound SFU event payload.
    var eventPublisher: AnyPublisher<Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload, Never> { get }

    func connect()
    func disconnect() async
    func disconnect(code: URLSessionWebSocketTask.CloseCode)
    func send(_ message: any StreamCore.SendableEvent)
    func inject(_ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload)
}

/// Owns the SFU signaling WebSocket, backed by `StreamCore.WebSocketClient`.
///
/// This is the single boundary that imports StreamCore for the SFU WebSocket.
/// It exposes a StreamCore-free, StreamVideo-typed surface (`SFUConnectionState`,
/// an SFU-payload event publisher, connect/disconnect/send) so `SFUAdapter` and
/// the WebRTC state machine never import StreamCore.
///
/// - TODO: [StreamCore migration] This isolation wrapper exists because video
///   still owns duplicated leaf types (`log`, `ClientError`, `DisposableBag`,
///   `Event`, `EventNotificationCenter`) that collide when StreamCore is
///   imported directly. Once those are unified on StreamCore (leaf migration),
///   `SFUAdapter` can import StreamCore directly and this wrapper can be
///   inlined/retired.
final class SFUWebSocket: SFUWebSocketProtocol, StreamCore.ConnectionStateDelegate, @unchecked Sendable {

    private let webSocket: StreamCore.WebSocketClient

    /// The current connection state, mapped from StreamCore's connection state.
    @Published private(set) var connectionState: SFUConnectionState = .initialized

    var connectionStatePublisher: AnyPublisher<SFUConnectionState, Never> {
        $connectionState.eraseToAnyPublisher()
    }

    /// The URL used for the WebSocket connection.
    let connectURL: URL

    /// Emits every inbound SFU event payload.
    var eventPublisher: AnyPublisher<Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload, Never> {
        webSocket
            .eventSubject
            .compactMap { $0 as? Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload }
            .eraseToAnyPublisher()
    }

    init(
        url: URL,
        sessionConfiguration: URLSessionConfiguration
    ) {
        connectURL = url
        webSocket = StreamCore.WebSocketClient(
            sessionConfiguration: sessionConfiguration,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: StreamCore.DefaultEventNotificationCenter(),
            webSocketClientType: .sfu,
            connectRequest: URLRequest(url: url),
            requiresAuth: false,
            pingRequestBuilder: { makeSFUHealthCheckPing() }
        )
        webSocket.connectionStateDelegate = self
    }

    func connect() {
        webSocket.connect()
    }

    func disconnect() async {
        await webSocket.disconnect()
    }

    func disconnect(code: URLSessionWebSocketTask.CloseCode) {
        webSocket.disconnect(code: code, source: .userInitiated) {}
    }

    /// Sends an outbound SFU message over the WebSocket.
    func send(_ message: any StreamCore.SendableEvent) {
        webSocket.engine?.send(message: message)
    }

    /// Re-injects a buffered SFU payload into the event stream (replay path).
    func inject(_ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) {
        webSocket.eventSubject.send(payload)
    }

    // MARK: - ConnectionStateDelegate

    func webSocketClient(
        _ client: StreamCore.WebSocketClient,
        didUpdateConnectionState state: StreamCore.WebSocketConnectionState
    ) {
        connectionState = .init(state)
    }
}

extension SFUConnectionState {
    /// Maps StreamCore's connection state into the video-side representation.
    init(_ state: StreamCore.WebSocketConnectionState) {
        switch state {
        case .initialized:
            self = .initialized
        case .connecting:
            self = .connecting
        case .authenticating:
            self = .authenticating
        case .connected:
            self = .connected
        case let .disconnecting(source):
            self = .disconnecting(source: .init(source))
        case let .disconnected(source):
            self = .disconnected(source: .init(source))
        }
    }
}

extension SFUConnectionState.DisconnectionSource {
    /// Maps StreamCore's disconnection source into the video-side representation.
    init(_ source: StreamCore.WebSocketConnectionState.DisconnectionSource) {
        switch source {
        case .userInitiated:
            self = .userInitiated
        case let .serverInitiated(error):
            self = .serverInitiated(error: error?.underlyingError)
        case .systemInitiated:
            self = .systemInitiated
        case .noPongReceived:
            self = .noPongReceived
        case .timeout:
            self = .timeout
        }
    }
}
