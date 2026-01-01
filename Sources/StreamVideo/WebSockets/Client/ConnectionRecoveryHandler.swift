//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type that keeps track of active chat components and asks them to reconnect when it's needed
protocol ConnectionRecoveryHandler: ConnectionStateDelegate, Sendable {}

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// When the status becomes `connected` the `/sync` endpoint is called
/// with `lastReceivedEventDate` and `cids` of watched channels.
///
/// We remember `lastReceivedEventDate` when state becomes `connecting` to catch the last event date
/// before the `HealthCheck` override the `lastReceivedEventDate` with the recent date.
///
final class DefaultConnectionRecoveryHandler: ConnectionRecoveryHandler, @unchecked Sendable {
    // MARK: - Properties
    
    private let webSocketClient: WebSocketClient
    private let eventNotificationCenter: EventNotificationCenter
    private let backgroundTaskScheduler: BackgroundTaskScheduler?
    private let internetConnection: InternetConnection
    private let reconnectionTimerType: Timer.Type
    private let keepConnectionAliveInBackground: Bool
    private let disposableBag = DisposableBag()
    private nonisolated(unsafe) var reconnectionStrategy: RetryStrategy
    private nonisolated(unsafe) var reconnectionTimer: TimerControl?
    private nonisolated(unsafe) var reconnectionPolicies: [AutomaticReconnectionPolicy]

    // MARK: - Init

    convenience init(
        webSocketClient: WebSocketClient,
        eventNotificationCenter: EventNotificationCenter,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        internetConnection: InternetConnection,
        reconnectionStrategy: RetryStrategy,
        reconnectionTimerType: Timer.Type,
        keepConnectionAliveInBackground: Bool
    ) {
        self.init(
            webSocketClient: webSocketClient,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: backgroundTaskScheduler,
            internetConnection: internetConnection,
            reconnectionStrategy: reconnectionStrategy,
            reconnectionTimerType: reconnectionTimerType,
            keepConnectionAliveInBackground: keepConnectionAliveInBackground,
            reconnectionPolicies: [
                WebSocketAutomaticReconnectionPolicy(webSocketClient),
                InternetAvailabilityReconnectionPolicy(internetConnection),
                CompositeReconnectionPolicy(.or, policies: [
                    BackgroundStateReconnectionPolicy(backgroundTaskScheduler),
                    CallKitReconnectionPolicy()
                ])
            ]
        )
    }

    init(
        webSocketClient: WebSocketClient,
        eventNotificationCenter: EventNotificationCenter,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        internetConnection: InternetConnection,
        reconnectionStrategy: RetryStrategy,
        reconnectionTimerType: Timer.Type,
        keepConnectionAliveInBackground: Bool,
        reconnectionPolicies: [AutomaticReconnectionPolicy]
    ) {
        self.webSocketClient = webSocketClient
        self.eventNotificationCenter = eventNotificationCenter
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.internetConnection = internetConnection
        self.reconnectionStrategy = reconnectionStrategy
        self.reconnectionTimerType = reconnectionTimerType
        self.keepConnectionAliveInBackground = keepConnectionAliveInBackground
        self.reconnectionPolicies = reconnectionPolicies

        subscribeOnNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
        cancelReconnectionTimer()
    }
}

// MARK: - Subscriptions

private extension DefaultConnectionRecoveryHandler {
    func subscribeOnNotifications() {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            backgroundTaskScheduler?.startListeningForAppStateUpdates(
                onEnteringBackground: { [weak self] in self?.appDidEnterBackground() },
                onEnteringForeground: { [weak self] in self?.appDidBecomeActive() }
            )

            internetConnection.notificationCenter.addObserver(
                self,
                selector: #selector(internetConnectionAvailabilityDidChange(_:)),
                name: .internetConnectionAvailabilityDidChange,
                object: nil
            )
        }
    }
    
    func unsubscribeFromNotifications() {
        Task(disposableBag: disposableBag) { @MainActor [backgroundTaskScheduler] in
            backgroundTaskScheduler?.stopListeningForAppStateUpdates()
        }

        internetConnection.notificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
}

// MARK: - Event handlers

extension DefaultConnectionRecoveryHandler {
    private func appDidBecomeActive() {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            log.debug("App -> ✅", subsystems: .webSocket)

            self?.backgroundTaskScheduler?.endTask()

            self?.reconnectIfNeeded()
        }
    }
    
    private func appDidEnterBackground() {
        log.debug("App -> 💤", subsystems: .webSocket)
        
        guard canBeDisconnected else {
            // Client is not trying to connect nor connected
            return
        }
        
        guard keepConnectionAliveInBackground else {
            // We immediately disconnect
            disconnectIfNeeded()
            return
        }
        
        guard let scheduler = backgroundTaskScheduler else { return }
                
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            let succeed = scheduler.beginTask { [weak self] in
                log.debug("Background task -> ❌", subsystems: .webSocket)

                self?.disconnectIfNeeded()
            }

            if succeed {
                log.debug("Background task -> ✅", subsystems: .webSocket)
            } else {
                // Can't initiate a background task, close the connection
                self?.disconnectIfNeeded()
            }
        }
    }
    
    @objc private func internetConnectionAvailabilityDidChange(_ notification: Notification) {
        guard let isAvailable = notification.internetConnectionStatus?.isAvailable else { return }
        
        log.debug("Internet -> \(isAvailable ? "✅" : "❌")", subsystems: .webSocket)
        
        if isAvailable {
            reconnectIfNeeded()
        } else {
            disconnectIfNeeded()
        }
    }
    
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        log.debug("Connection state: \(state)", subsystems: .webSocket)
        
        switch state {
        case .connecting:
            cancelReconnectionTimer()
            
        case .connected:
            reconnectionStrategy.resetConsecutiveFailures()
        case .disconnected:
            scheduleReconnectionTimerIfNeeded()
        case .initialized, .authenticating, .disconnecting:
            break
        }
    }
}

// MARK: - Disconnection

private extension DefaultConnectionRecoveryHandler {
    func disconnectIfNeeded() {
        guard canBeDisconnected else { return }
        
        webSocketClient.disconnect(source: .systemInitiated) {
            log.debug("Did disconnect automatically", subsystems: .webSocket)
        }
    }
    
    var canBeDisconnected: Bool {
        let state = webSocketClient.connectionState
        
        switch state {
        case .connecting, .authenticating, .connected:
            log.debug("Will disconnect automatically from \(state) state", subsystems: .webSocket)
            
            return true
        default:
            log.debug("Disconnect is not needed in \(state) state", subsystems: .webSocket)
            
            return false
        }
    }
}

// MARK: - Reconnection

private extension DefaultConnectionRecoveryHandler {
    func reconnectIfNeeded() {
        guard canReconnectAutomatically else { return }
                
        webSocketClient.connect()
    }
    
    var canReconnectAutomatically: Bool {
        reconnectionPolicies.first { $0.canBeReconnected() == false } == nil
    }
}

// MARK: - Reconnection Timer

private extension DefaultConnectionRecoveryHandler {
    func scheduleReconnectionTimerIfNeeded() {
        guard canReconnectAutomatically else { return }
        
        scheduleReconnectionTimer()
    }
    
    func scheduleReconnectionTimer() {
        let delay = reconnectionStrategy.getDelayAfterTheFailure()
        
        log.debug("Timer ⏳ \(delay) sec", subsystems: .webSocket)
        
        reconnectionTimer = reconnectionTimerType.schedule(
            timeInterval: delay,
            queue: .main,
            onFire: { [weak self] in
                log.debug("Timer 🔥", subsystems: .webSocket)
                
                self?.reconnectIfNeeded()
            }
        )
    }
    
    func cancelReconnectionTimer() {
        guard reconnectionTimer != nil else { return }
        
        log.debug("Timer ❌", subsystems: .webSocket)
        
        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }
}

// MARK: - Automatic Reconnection Policies

protocol AutomaticReconnectionPolicy {
    func canBeReconnected() -> Bool
}

struct WebSocketAutomaticReconnectionPolicy: AutomaticReconnectionPolicy {
    private var webSocketClient: WebSocketClient

    init(_ webSocketClient: WebSocketClient) {
        self.webSocketClient = webSocketClient
    }

    func canBeReconnected() -> Bool {
        webSocketClient.connectionState.isAutomaticReconnectionEnabled
    }
}

struct InternetAvailabilityReconnectionPolicy: AutomaticReconnectionPolicy {
    private var internetConnection: InternetConnection

    init(_ internetConnection: InternetConnection) {
        self.internetConnection = internetConnection
    }

    func canBeReconnected() -> Bool {
        internetConnection.status.isAvailable
    }
}

struct BackgroundStateReconnectionPolicy: AutomaticReconnectionPolicy {
    private var backgroundTaskScheduler: BackgroundTaskScheduler?

    init(_ backgroundTaskScheduler: BackgroundTaskScheduler?) {
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func canBeReconnected() -> Bool {
        backgroundTaskScheduler?.isAppActive ?? true
    }
}

struct CallKitReconnectionPolicy: AutomaticReconnectionPolicy {
    @Injected(\.callKitService) private var callKitService

    init() {}

    func canBeReconnected() -> Bool {
        callKitService.callCount > 0
    }
}

struct CompositeReconnectionPolicy: AutomaticReconnectionPolicy {
    enum Operator { case and, or }

    private var `operator`: Operator
    private var policies: [AutomaticReconnectionPolicy]

    init(_ operator: Operator, policies: [AutomaticReconnectionPolicy]) {
        self.operator = `operator`
        self.policies = policies
    }

    func canBeReconnected() -> Bool {
        switch `operator` {
        case .and:
            return policies.first { $0.canBeReconnected() == false } == nil
        case .or:
            return policies.first { $0.canBeReconnected() } != nil
        }
    }
}
