//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

struct MockSFUStack: @unchecked Sendable {
    /// Reference box so the adapter's `refresh` factory can return a socket
    /// injected after construction (mirrors the old factory-stub pattern).
    final class Box: @unchecked Sendable { var socket: MockSFUWebSocket; init(_ s: MockSFUWebSocket) { socket = s } }

    var webSocket: MockSFUWebSocket
    var service: MockSignalServer
    let adapter: SFUAdapter
    private let box: Box

    /// The web socket returned by the adapter's `refresh` factory. Defaults to
    /// `webSocket`; set to a fresh mock to simulate a refreshed connection.
    var nextWebSocket: MockSFUWebSocket {
        get { box.socket }
        nonmutating set { box.socket = newValue }
    }

    init() {
        let webSocket = MockSFUWebSocket()
        let service = MockSignalServer()
        let box = Box(webSocket)
        self.webSocket = webSocket
        self.service = service
        self.box = box
        adapter = SFUAdapter(
            signalService: service,
            webSocket: webSocket,
            webSocketFactory: { _, _ in box.socket }
        )
    }

    // MARK: - WebSocket

    func setConnectionState(to state: WebSocketConnectionState) {
        webSocket.simulate(state: .init(webSocketConnectionState: state))
    }

    func receiveEvent(_ event: WrappedEvent) {
        if case let .sfuEvent(payload) = event {
            webSocket.receive(payload)
        }
    }
}

// Test-only mapping from the (coordinator) `WebSocketConnectionState` used by
// existing tests into the SFU-specific `SFUConnectionState`. Kept in the test
// target since production never converts between the two.
extension SFUConnectionState {
    init(webSocketConnectionState state: WebSocketConnectionState) {
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
    init(_ source: WebSocketConnectionState.DisconnectionSource) {
        switch source {
        case .userInitiated:
            self = .userInitiated
        case let .serverInitiated(error):
            self = .serverInitiated(error: error?.underlyingError)
        case .systemInitiated:
            self = .systemInitiated
        case .noPongReceived:
            self = .noPongReceived
        }
    }
}
