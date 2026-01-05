//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

class WebSocketClient: @unchecked Sendable {
    /// The notification center `WebSocketClient` uses to send notifications about incoming events.
    let eventNotificationCenter: EventNotificationCenter

    /// The batch of events received via the web-socket that wait to be processed.
    private(set) lazy var eventsBatcher = environment.eventBatcherBuilder { [weak self] events, completion in
        guard let self else { return }
        events.forEach { [eventSubject] in eventSubject.send($0) }
        eventNotificationCenter.process(events, completion: completion)
    }

    /// The current state the web socket connection.
    @Atomic private(set) var connectionState: WebSocketConnectionState = .initialized {
        didSet {
            pingController.connectionStateDidChange(connectionState)

            guard connectionState != oldValue else { return }

            log.info("Web socket connection state changed: \(connectionState)", subsystems: .webSocket)

            connectionSubject.send(connectionState)
            connectionStateDelegate?.webSocketClient(self, didUpdateConnectionState: connectionState)
        }
    }

    let connectionSubject = PassthroughSubject<WebSocketConnectionState, Never>()
    let eventSubject = PassthroughSubject<WrappedEvent, Never>()

    weak var connectionStateDelegate: ConnectionStateDelegate?

    var connectURL: URL

    var requiresAuth: Bool

    /// The decoder used to decode incoming events
    private let eventDecoder: AnyEventDecoder

    /// The web socket engine used to make the actual WS connection
    private(set) var engine: WebSocketEngine?

    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.getStream.video.core.web_socket_engine_queue", qos: .userInitiated)

    /// The session config used for the web socket engine
    private let sessionConfiguration: URLSessionConfiguration

    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment

    private let webSocketClientType: WebSocketClientType

    let pingController: WebSocketPingController

    private func createEngineIfNeeded(for connectURL: URL) -> WebSocketEngine {
        let request = URLRequest(url: connectURL)

        if let existedEngine = engine, existedEngine.request == request {
            return existedEngine
        }

        let engine = environment.createEngine(request, sessionConfiguration, engineQueue)
        engine.delegate = self
        return engine
    }

    var onWSConnectionEstablished: (() -> Void)?
    var onConnected: (() -> Void)?

    init(
        sessionConfiguration: URLSessionConfiguration,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        webSocketClientType: WebSocketClientType,
        environment: Environment = .init(),
        connectURL: URL,
        requiresAuth: Bool = true
    ) {
        self.environment = environment
        self.sessionConfiguration = sessionConfiguration
        self.webSocketClientType = webSocketClientType
        self.eventDecoder = eventDecoder
        self.connectURL = connectURL
        self.eventNotificationCenter = eventNotificationCenter
        self.requiresAuth = requiresAuth
        pingController = environment.createPingController(
            environment.timerType,
            engineQueue,
            webSocketClientType
        )
        
        pingController.delegate = self
    }

    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    func connect() {
        switch connectionState {
        // Calling connect in the following states has no effect
        case .connecting, .authenticating, .connected(healthCheckInfo: _):
            return
        default: break
        }

        engine = createEngineIfNeeded(for: connectURL)

        connectionState = .connecting

        engineQueue.async { [weak engine] in
            engine?.connect()
        }
    }

    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.userInitiated`.
    func disconnect(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @Sendable @escaping () -> Void
    ) {
        connectionState = .disconnecting(source: source)
        engineQueue.async { [engine, eventsBatcher] in
            engine?.disconnect(with: code)

            eventsBatcher.processImmediately(completion: completion)
        }
    }

    func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }
            disconnect {
                continuation.resume()
            }
        }
    }
}

protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState)
}

extension WebSocketClient {
    /// An object encapsulating all dependencies of `WebSocketClient`.
    struct Environment {
        typealias CreatePingController = (
            _ timerType: Timer.Type,
            _ timerQueue: DispatchQueue,
            _ webSocketClientType: WebSocketClientType
        ) -> WebSocketPingController

        typealias CreateEngine = (
            _ request: URLRequest,
            _ sessionConfiguration: URLSessionConfiguration,
            _ callbackQueue: DispatchQueue
        ) -> WebSocketEngine

        var timerType: Timer.Type = DefaultTimer.self

        var createPingController: CreatePingController = WebSocketPingController.init

        var createEngine: CreateEngine = {
            URLSessionWebSocketEngine(request: $0, sessionConfiguration: $1, callbackQueue: $2)
        }

        var httpClientBuilder: () -> HTTPClient = {
            URLSessionClient(
                urlSession: StreamVideo.Environment.makeURLSession()
            )
        }

        var eventBatcherBuilder: (
            _ handler: @Sendable @escaping ([WrappedEvent], @Sendable @escaping () -> Void) -> Void
        ) -> EventBatcher = {
            Batcher<WrappedEvent>(period: 0.0, handler: $0)
        }
    }
}

// MARK: - Web Socket Delegate

extension WebSocketClient: WebSocketEngineDelegate {
    func webSocketDidConnect() {
        log.debug("Web socket connection established", subsystems: .webSocket)
        connectionState = .authenticating
        onWSConnectionEstablished?()
    }

    func webSocketDidReceiveMessage(_ data: Data) {
        var event: WrappedEvent

        do {
            event = try eventDecoder.decode(from: data)
        } catch {
            do {
                let apiError = try JSONDecoder.default.decode(APIErrorContainer.self, from: data).error
                log.error("web socket error \(apiError.message)", subsystems: .webSocket, error: apiError)
            } catch let decodingError {
                log.warning(
                    """
                    Decoding websocket payload failed
                    payload: \(String(data: data, encoding: .utf8) ?? "-")

                    Error: \(decodingError)
                    """,
                    subsystems: .webSocket
                )
            }
            return
        }

        if let error = event.error() {
            log.error("Received an error webSocket event.", subsystems: .webSocket, error: error)
            connectionState = .disconnecting(source: .serverInitiated(error: ClientError(with: error)))
            return
        } else {
            log.info("Received webSocket event \(event.name).", subsystems: .webSocket)
        }

        // healthcheck events are not passed to batcher
        if let info = event.healthcheck() {
            handle(healthcheck: event, info: info)
            return
        }

        eventsBatcher.append(event)
    }

    func webSocketDidDisconnect(error engineError: WebSocketEngineError?) {
        switch connectionState {
        case .connecting, .authenticating, .connected:
            let serverError = engineError.map { ClientError.WebSocket(with: $0) }

            connectionState = .disconnected(source: .serverInitiated(error: serverError))

        case let .disconnecting(source):
            connectionState = .disconnected(source: source)

        case .initialized, .disconnected:
            log.error(
                "Web socket can not be disconnected when in \(connectionState) state",
                subsystems: .webSocket,
                error: engineError
            )
        }
    }

    private func handle(healthcheck: WrappedEvent, info: HealthCheckInfo) {
        log.debug("Handling healthcheck", subsystems: .webSocket)

        if connectionState == .authenticating {
            connectionState = .connected(healthCheckInfo: info)
            onConnected?()
        }

        // We send the healthcheck to the eventSubject so that observers
        // (e.g. SFUEventAdapter) get updated.
        eventSubject.send(healthcheck)
        eventNotificationCenter.process(healthcheck, postNotification: false) { [weak self] in
            self?.engineQueue.async { [weak self] in
                self?.pingController.pongReceived()
                self?.connectionState = .connected(healthCheckInfo: info)
            }
        }
    }
}

// MARK: - Ping Controller Delegate

extension WebSocketClient: WebSocketPingControllerDelegate {

    func sendPing(healthCheckEvent: SendableEvent) {
        engineQueue.async { [weak engine] in
            if case .connected(healthCheckInfo: _) = self.connectionState {
                engine?.send(message: healthCheckEvent)
            }
        }
    }

    func sendPing() {
        engine?.sendPing()
    }

    func disconnectOnNoPongReceived() {
        log.debug("disconnecting from \(connectURL)", subsystems: .webSocket)
        disconnect(source: .noPongReceived) {
            log.debug("Websocket is disconnected because of no pong received", subsystems: .webSocket)
        }
    }
}

enum WebSocketClientType {
    case coordinator
    case sfu
}

// MARK: - Notifications

extension Notification.Name {
    /// The name of the notification posted when a new event is published/
    static let NewEventReceived = Notification.Name("io.getStream.video.core.new_event_received")
}

extension Notification {
    private static let eventKey = "io.getStream.video.core.event_key"

    init(newEventReceived event: Event, sender: Any) {
        self.init(name: .NewEventReceived, object: sender, userInfo: [Self.eventKey: event])
    }

    var event: WrappedEvent? {
        userInfo?[Self.eventKey] as? WrappedEvent
    }
}

// MARK: - Test helpers

#if TESTS
extension WebSocketClient {
    /// Simulates connection status change
    func simulateConnectionStatus(_ status: WebSocketConnectionState) {
        connectionState = status
    }
}
#endif

extension ClientError {
    public class WebSocket: ClientError, @unchecked Sendable {}
}

struct WSDisconnected: Event {}
struct WSConnected: Event {}
