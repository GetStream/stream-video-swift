//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
protocol WebSocketPingControllerDelegate: AnyObject {
        
    /// `WebSocketPingController` will call this function periodically to keep a connection alive.
    func sendPing(healthCheckEvent: SendableEvent)
    
    /// Regular ping, without sending any data.
    func sendPing()
    
    /// `WebSocketPingController` will call this function to force disconnect `WebSocketClient`.
    func disconnectOnNoPongReceived()
}

struct HealthCheckInfo: Equatable {
    var coordinatorHealthCheck: HealthCheckEvent?
    var sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse?
}

protocol HealthCheck: Event, Equatable {}

/// The controller manages ping and pong timers. It sends ping periodically to keep a web socket connection alive.
/// After ping is sent, a pong waiting timer is started, and if pong does not come, a forced disconnect is called.
class WebSocketPingController {
    /// The time interval to ping connection to keep it alive.
    /// - Note:
    /// Updated to 5 seconds based on https://www.notion.so/stream-wiki/Improved-Reconnects-and-ICE-connection-handling-2186a5d7f9f680c29236c2c37cfa11a3?source=copy_link#2186a5d7f9f68043968df9453ef5fa88
    static let pingTimeInterval: TimeInterval = 5
    /// The time interval for pong timeout.
    static let pongTimeoutTimeInterval: TimeInterval = 3
    
    private let timerType: Timer.Type
    private let timerQueue: DispatchQueue
    
    /// The timer used for scheduling `ping` calls
    private var pingTimerControl: RepeatingTimerControl?
    
    /// The pong timeout timer.
    private var pongTimeoutTimer: TimerControl?
    
    private let webSocketClientType: WebSocketClientType
        
    /// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
    weak var delegate: WebSocketPingControllerDelegate?
    
    deinit {
        cancelPongTimeoutTimer()
    }
    
    /// Creates a ping controller.
    /// - Parameters:
    ///   - timerType: a timer type.
    ///   - timerQueue: a timer dispatch queue.
    init(
        timerType: Timer.Type,
        timerQueue: DispatchQueue,
        webSocketClientType: WebSocketClientType
    ) {
        self.timerType = timerType
        self.timerQueue = timerQueue
        self.webSocketClientType = webSocketClientType
    }
    
    /// `WebSocketClient` should call this when the connection state did change.
    func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        guard delegate != nil else { return }
        
        cancelPongTimeoutTimer()
        schedulePingTimerIfNeeded()
        
        if connectionState.isConnected {
            log.info("Resume WebSocket Ping timer", subsystems: .httpRequests)
            pingTimerControl?.resume()
        } else {
            pingTimerControl?.suspend()
        }
    }
    
    // MARK: - Ping
    
    private func sendPing() {
        schedulePongTimeoutTimer()

        log.info("WebSocket Ping", subsystems: .webSocket)
        if webSocketClientType == .coordinator {
            delegate?.sendPing()
        } else {
            var sfuRequest = Stream_Video_Sfu_Event_SfuRequest()
            let healthCheckEvent = Stream_Video_Sfu_Event_HealthCheckRequest()
            sfuRequest.healthCheckRequest = healthCheckEvent
            delegate?.sendPing(healthCheckEvent: sfuRequest)
        }
    }
    
    func pongReceived() {
        log.info("WebSocket Pong", subsystems: .webSocket)
        cancelPongTimeoutTimer()
    }
    
    // MARK: Timers
    
    private func schedulePingTimerIfNeeded() {
        guard pingTimerControl == nil else { return }
        pingTimerControl = timerType.scheduleRepeating(timeInterval: Self.pingTimeInterval, queue: timerQueue) { [weak self] in
            self?.sendPing()
        }
    }
    
    private func schedulePongTimeoutTimer() {
        cancelPongTimeoutTimer()
        // Start pong timeout timer.
        pongTimeoutTimer = timerType.schedule(timeInterval: Self.pongTimeoutTimeInterval, queue: timerQueue) { [weak self] in
            log.info("WebSocket Pong timeout. Reconnect", subsystems: .webSocket)
            self?.delegate?.disconnectOnNoPongReceived()
        }
    }
    
    private func cancelPongTimeoutTimer() {
        pongTimeoutTimer?.cancel()
        pongTimeoutTimer = nil
    }
}
