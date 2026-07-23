//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
@testable import StreamVideo

struct MockSFUStack: @unchecked Sendable {
    private final class WebSocketStorage: @unchecked Sendable {
        private let lock = NSLock()
        private var value: MockSFUWebSocket

        init(_ value: MockSFUWebSocket) {
            self.value = value
        }

        var current: MockSFUWebSocket {
            get {
                lock.lock()
                defer { lock.unlock() }
                return value
            }
            set {
                lock.lock()
                value = newValue
                lock.unlock()
            }
        }
    }

    var webSocket: MockSFUWebSocket
    var service: MockSignalServer
    let adapter: SFUAdapter
    private let webSocketStorage: WebSocketStorage

    var nextWebSocket: MockSFUWebSocket {
        get { webSocketStorage.current }
        nonmutating set { webSocketStorage.current = newValue }
    }

    init() {
        let webSocket = MockSFUWebSocket()
        let service = MockSignalServer()
        let webSocketStorage = WebSocketStorage(webSocket)
        self.webSocket = webSocket
        self.service = service
        self.webSocketStorage = webSocketStorage
        adapter = SFUAdapter(
            signalService: service,
            webSocket: webSocket,
            webSocketFactory: { [webSocketStorage] _, _, _ in
                webSocketStorage.current
            }
        )
    }

    // MARK: - WebSocket

    func setConnectionState(to state: WebSocketConnectionState) {
        webSocket.simulate(state: state)
    }

    func receiveEvent(
        _ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload
    ) {
        webSocket.inject(payload)
    }
}
