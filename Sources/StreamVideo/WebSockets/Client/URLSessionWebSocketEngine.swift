//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class URLSessionWebSocketEngine: NSObject, WebSocketEngine, @unchecked Sendable {
    private weak var task: URLSessionWebSocketTask? {
        didSet {
            oldValue?.cancel()
        }
    }

    let request: URLRequest
    private var session: URLSession?
    let delegateOperationQueue: OperationQueue
    let sessionConfiguration: URLSessionConfiguration
    var urlSessionDelegateHandler: URLSessionDelegateHandler?

    var callbackQueue: DispatchQueue { delegateOperationQueue.underlyingQueue! }

    weak var delegate: WebSocketEngineDelegate?

    required init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
        self.request = request
        self.sessionConfiguration = sessionConfiguration

        delegateOperationQueue = OperationQueue(maxConcurrentOperationCount: 1)
        delegateOperationQueue.underlyingQueue = callbackQueue

        super.init()
    }

    deinit {
        disconnect()
    }

    func connect() {
        urlSessionDelegateHandler = makeURLSessionDelegateHandler()

        session = URLSession(
            configuration: sessionConfiguration,
            delegate: urlSessionDelegateHandler,
            delegateQueue: delegateOperationQueue
        )

        log.debug(
            "Making Websocket upgrade request: \(request.url?.absoluteString)\n"
                + "Headers:\n\(String(describing: request.allHTTPHeaderFields))\n"
                + "Query items:\n\(request.queryItems.prettyPrinted)",
            subsystems: .webSocket
        )

        task = session?.webSocketTask(with: request)
        doRead()
        task?.resume()
    }

    func disconnect() {
        disconnect(with: .normalClosure)
    }

    func disconnect(with code: URLSessionWebSocketTask.CloseCode) {
        task?.cancel(with: code, reason: nil)
        session?.invalidateAndCancel()

        session = nil
        task = nil
        urlSessionDelegateHandler = nil
    }

    func send(message: SendableEvent) {
        do {
            let data = try message.serializedData()
            send(data: data)
        } catch {
            log.error("Failed sending SendableEvent", subsystems: .webSocket, error: error)
        }
    }

    func send(jsonMessage: Codable) {
        do {
            let data = try JSONEncoder().encode(jsonMessage)
            send(data: data)
        } catch {
            log.error("Failed sending JSON message", subsystems: .webSocket, error: error)
        }
    }

    func sendPing() {
        task?.sendPing { _ in }
    }

    // MARK: - Private Helpers

    private func send(data: Data) {
        let message: URLSessionWebSocketTask.Message = .data(data)
        task?.send(message) { [weak self] error in
            if error == nil {
                log.debug(
                    """
                    Event message sent
                    \(String(data: data, encoding: .utf8))
                    """, subsystems: .webSocket
                )
                self?.doRead()
            }
        }
    }

    private func doRead() {
        task?.receive { [weak self] result in
            guard let self = self, task != nil else {
                return
            }

            switch result {
            case let .success(message):
                if case let .data(data) = message {
                    log.debug("Received webSocket message: \(data.debugPrettyPrintedJSON)", subsystems: .webSocket)
                    self.callbackQueue.async { [weak self] in
                        guard self?.task != nil else { return }
                        self?.delegate?.webSocketDidReceiveMessage(data)
                    }
                } else if case let .string(string) = message {
                    let messageData = Data(string.utf8)
                    log.debug("Received webSocket message:\(messageData.debugPrettyPrintedJSON)", subsystems: .webSocket)
                    self.callbackQueue.async { [weak self] in
                        guard self?.task != nil else { return }
                        self?.delegate?.webSocketDidReceiveMessage(messageData)
                    }
                }
                self.doRead()

            case let .failure(error):
                log.error("Failed while trying to receive webSocket message.", subsystems: .webSocket, error: error)
            }
        }
    }

    private func makeURLSessionDelegateHandler() -> URLSessionDelegateHandler {
        let urlSessionDelegateHandler = URLSessionDelegateHandler()
        urlSessionDelegateHandler.onOpen = { [weak self] _ in
            self?.performDelegateOperation { $0?.webSocketDidConnect() }
        }

        urlSessionDelegateHandler.onClose = { [weak self] closeCode, reason in
            let error: WebSocketEngineError?

            if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
                error = WebSocketEngineError(
                    reason: reasonString,
                    code: closeCode.rawValue,
                    engineError: nil
                )
                log.error("WebSocket onClose", subsystems: .webSocket, error: error)
            } else {
                error = nil
            }

            self?.performDelegateOperation { $0?.webSocketDidDisconnect(error: error) }
        }

        urlSessionDelegateHandler.onCompletion = { [weak self] error in
            // If we received this callback because we closed the WS connection
            // intentionally, `error` param will be `nil`.
            // Delegate is already informed with `didCloseWith` callback,
            // so we don't need to call delegate again.
            guard let error = error else { return }

            self?.callbackQueue.async { [weak self] in
                let socketError = WebSocketEngineError(error: error)
                log.error("WebSocket onClose", subsystems: .webSocket, error: error)
                self?.delegate?.webSocketDidDisconnect(error: socketError)
            }
        }

        return urlSessionDelegateHandler
    }

    private func performDelegateOperation(
        _ operation: @Sendable @escaping (WebSocketEngineDelegate?) -> Void
    ) {
        callbackQueue.async { [weak delegate] in
            operation(delegate)
        }
    }
}

final class URLSessionDelegateHandler: NSObject, URLSessionDataDelegate, URLSessionWebSocketDelegate, @unchecked Sendable {
    var onOpen: ((_ protocol: String?) -> Void)?
    var onClose: ((_ code: URLSessionWebSocketTask.CloseCode, _ reason: Data?) -> Void)?
    var onCompletion: ((Error?) -> Void)?

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        onOpen?(`protocol`)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        onClose?(closeCode, reason)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onCompletion?(error)
    }
}
