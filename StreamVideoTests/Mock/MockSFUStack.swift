//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
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

    // These helpers intentionally target the original socket. Recovery tests
    // use it to establish and fail the initial connection after configuring
    // `nextWebSocket` as its replacement.
    func setConnectionState(to state: WebSocketConnectionState) {
        webSocket.simulate(state: state)
    }

    func receiveEvent(_ event: WrappedEvent) {
        if case let .sfuEvent(payload) = event {
            webSocket.receive(payload)
        }
    }
}
