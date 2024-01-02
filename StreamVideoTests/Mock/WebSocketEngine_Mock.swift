//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class WebSocketEngine_Mock: WebSocketEngine {
    
    var request: URLRequest
    var sessionConfiguration: URLSessionConfiguration
    var isConnected: Bool = false
    var callbackQueue: DispatchQueue
    weak var delegate: WebSocketEngineDelegate?

    /// How many times was `connect()` called
    @Atomic var connect_calledCount = 0

    /// How many times was `disconnect()` called
    @Atomic var disconnect_calledCount = 0

    /// How many times was `sendPing()` called
    @Atomic var sendPing_calledCount = 0

    convenience init() {
        self.init(request: .init(url: URL(string: "test_url")!), sessionConfiguration: .ephemeral, callbackQueue: .main)
    }

    required init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
        self.request = request
        self.sessionConfiguration = sessionConfiguration
        self.callbackQueue = callbackQueue
    }

    func connect() {
        connect_calledCount += 1
    }

    func disconnect() {
        disconnect_calledCount += 1
    }

    func sendPing() {
        sendPing_calledCount += 1
    }
    
    func send(message: SendableEvent) {}
    
    func send(jsonMessage: Codable) {}

    // MARK: - Functions to simulate behavior

    func simulateConnectionSuccess() {
        isConnected = true
        delegate?.webSocketDidConnect()
    }

    func simulateMessageReceived(_ json: [String: Any] = [:]) {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        simulateMessageReceived(data)
    }

    func simulateMessageReceived(_ data: Data) {
        delegate?.webSocketDidReceiveMessage(data)
    }

    func simulatePong() {
        simulateMessageReceived(.healthCheckEvent(userId: .unique, connectionId: .unique))
    }

    func simulateDisconnect(_ error: WebSocketEngineError? = nil) {
        isConnected = false
        delegate?.webSocketDidDisconnect(error: error)
    }
}

extension Dictionary {
    /// Helper function to create a `health.check` event JSON with the given `userId` and `connectId`.
    static func healthCheckEvent(userId: String, connectionId: String) -> [String: Any] {
        [
            "created_at": "2020-05-02T13:21:03.862065063Z",
            "type": "health.check",
            "connection_id": connectionId
        ]
    }
}
