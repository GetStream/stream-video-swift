//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketEngine: AnyObject, Sendable {
    var request: URLRequest { get }
    var callbackQueue: DispatchQueue { get }
    var delegate: WebSocketEngineDelegate? { get set }
    
    init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue)
    
    func connect()
    func disconnect()
    func disconnect(with code: URLSessionWebSocketTask.CloseCode)
    func send(message: SendableEvent)
    func send(jsonMessage: Codable)
    func sendPing()
}

protocol WebSocketEngineDelegate: AnyObject, Sendable {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: WebSocketEngineError?)
    func webSocketDidReceiveMessage(_ data: Data)
}

struct WebSocketEngineError: Error {
    static let stopErrorCode = 1000
    
    let reason: String
    let code: Int
    let engineError: Error?
    
    var localizedDescription: String { reason }
}

extension WebSocketEngineError {
    init(error: Error?) {
        if let error = error {
            self.init(
                reason: error.localizedDescription,
                code: (error as NSError).code,
                engineError: error
            )
        } else {
            self.init(
                reason: "Unknown",
                code: 0,
                engineError: nil
            )
        }
    }
}
