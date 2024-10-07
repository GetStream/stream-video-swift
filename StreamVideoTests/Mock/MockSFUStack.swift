//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

struct MockSFUStack {
    var webSocket: MockWebSocketClient
    let webSocketFactory: MockWebSocketClientFactory
    let service: MockSignalServer
    let adapter: SFUAdapter

    init() {
        let webSocket = MockWebSocketClient(webSocketClientType: .sfu)
        let webSocketFactory = MockWebSocketClientFactory()
        let service = MockSignalServer()
        self.webSocket = webSocket
        self.service = service
        self.webSocketFactory = webSocketFactory
        adapter = SFUAdapter(
            signalService: service,
            webSocket: webSocket,
            webSocketFactory: webSocketFactory
        )
    }

    // MARK: - WebSocket

    func setConnectionState(to state: WebSocketConnectionState) {
        webSocket.stub(for: \.connectionState, with: state)
        webSocket.connectionStateDelegate?.webSocketClient(
            webSocket,
            didUpdateConnectionState: state
        )
    }

    func receiveEvent(_ event: WrappedEvent) {
        webSocket.eventSubject.send(event)
    }
}
