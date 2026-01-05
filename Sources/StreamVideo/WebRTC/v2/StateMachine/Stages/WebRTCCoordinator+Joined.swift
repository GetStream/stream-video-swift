//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a joined stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the joined stage.
    /// - Returns: A `JoinedStage` instance representing the joined state of
    ///   the WebRTC coordinator.
    static func joined(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        JoinedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the joined stage in the WebRTC coordinator state machine.
    final class JoinedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        @Injected(\.internetConnectionObserver) private var internetConnectionObserver
        @Injected(\.audioStore) private var audioStore

        private let disposableBag = DisposableBag()
        private var updateSubscriptionsAdapter: WebRTCUpdateSubscriptionsAdapter?
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

        /// Initializes a new instance of `JoinedStage`.
        /// - Parameter context: The context for the joined stage.
        init(
            _ context: Context
        ) {
            super.init(id: .joined, context: context)
        }

        deinit {
            disposableBag.removeAll()
        }

        /// Performs the transition from a previous stage to this joined stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `JoinedStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: `.joining`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                execute()
                return self
            default:
                return nil
            }
        }

        /// Executes the joined stage logic.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    guard
                        context.coordinator != nil
                    else {
                        throw ClientError(
                            "WebRCTCoordinator instance not available."
                        )
                    }

                    try Task.checkCancellation()

                    // We set the reconnectionStrategy to rejoin as default.
                    context.reconnectionStrategy = .rejoin

                    try Task.checkCancellation()

                    let migrationStatusObserver = context.migrationStatusObserver
                    let previousSFUAdapter = context.previousSFUAdapter
                    await cleanUpPreviousSessionIfRequired()

                    try Task.checkCancellation()

                    try await observeMigrationStatusIfRequired(
                        migrationStatusObserver,
                        previousSFUAdapter: previousSFUAdapter
                    )

                    observeInternetConnection()

                    try Task.checkCancellation()

                    await observeConnection()

                    try Task.checkCancellation()

                    await observeCallEndedEvent()

                    try Task.checkCancellation()

                    await observeMigrationEvent()

                    try Task.checkCancellation()

                    await observeDisconnectEvent()

                    try Task.checkCancellation()

                    await observePreferredReconnectionStrategy()

                    try Task.checkCancellation()

                    await observePeerConnectionState()

                    try Task.checkCancellation()

                    await observeParticipantSignalLostEvent()

                    try Task.checkCancellation()

                    await observeHealthCheckResponses()

                    try Task.checkCancellation()

                    await configureStatsCollectionAndDelivery()

                    try Task.checkCancellation()

                    await configureUpdateSubscriptions()
                } catch {
                    await cleanUpPreviousSessionIfRequired()
                    transitionDisconnectOrError(error)
                }
            }
        }

        /// Cleans up the previous WebRTC session, including closing and removing the
        /// previous publisher, subscriber, and SFU adapter. It also resets the migration
        /// and rejoining state in the context.
        private func cleanUpPreviousSessionIfRequired() async {
            await context.previousSessionPublisher?.close()
            await context.previousSessionSubscriber?.close()
            context.previousSessionPublisher = nil
            context.previousSessionSubscriber = nil
            context.previousSFUAdapter = nil
            context.migratingFromSFU = ""
            context.isRejoiningFromSessionID = nil
            context.migrationStatusObserver = nil
        }

        /// Observes the migration status if a `WebRTCMigrationStatusObserver` is provided.
        /// If migration is successful, the previous SFU (Selective Forwarding Unit)
        /// adapter is disconnected. If migration fails, the reconnection strategy is set
        /// to rejoin, and an error is logged.
        ///
        /// - Parameters:
        ///   - migrationStatusObserver: An optional observer that tracks the migration status.
        ///   - previousSFUAdapter: The previous SFU adapter that should be disconnected after migration.
        /// - Throws: An error if the migration status observation fails or if the task is cancelled.
        private func observeMigrationStatusIfRequired(
            _ migrationStatusObserver: WebRTCMigrationStatusObserver?,
            previousSFUAdapter: SFUAdapter?
        ) async throws {
            if let migrationStatusObserver = migrationStatusObserver {
                let task = Task(disposableBag: disposableBag) { [weak self] in
                    guard let self else { return }
                    do {
                        try Task.checkCancellation()
                        try await migrationStatusObserver
                            .observeMigrationStatus()
                        await previousSFUAdapter?.disconnect()
                    } catch is CancellationError {
                        /* No-op */
                    } catch {
                        context.reconnectionStrategy = .rejoin
                        log.warning("Will disconnect because migrationStatus failed.", subsystems: .webRTC)
                        throw error
                    }
                }
                _ = try await task.value
            } else {
                await previousSFUAdapter?.disconnect()
            }
        }

        /// Observes changes in the WebRTC connection state (disconnecting or
        /// disconnected) from the SFU (Selective Forwarding Unit) adapter. Based on
        /// the disconnection source, the method sets an appropriate reconnection
        /// strategy and handles the disconnection.
        private func observeConnection() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .$connectionState
                .compactMap {
                    switch $0 {
                    case let .disconnecting(source):
                        return source
                    case let .disconnected(source):
                        return source
                    default:
                        return nil
                    }
                }
                .receive(on: processingQueue)
                .sink { [weak self] (source: WebSocketConnectionState.DisconnectionSource) in
                    guard let self else { return }
                    context.disconnectionSource = source
                    if let sfuError = (source.serverError?.underlyingError as? Stream_Video_Sfu_Models_Error) {
                        context.reconnectionStrategy = sfuError.shouldRetry
                            ? .fast(
                                disconnectedSince: .init(),
                                deadline: context.fastReconnectDeadlineSeconds
                            )
                            : .rejoin
                    } else {
                        context.reconnectionStrategy = .fast(
                            disconnectedSince: .init(),
                            deadline: context.fastReconnectDeadlineSeconds
                        )
                    }

                    log
                        .warning(
                            """
                            Will disconnect because ws connection state changed 
                            to disconnecting/disconnected with source:\(source).
                            """,
                            subsystems: .webRTC
                        )
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Observes call-ended events from the SFU (Selective Forwarding Unit) adapter.
        /// When a `Stream_Video_Sfu_Event_CallEnded` event is detected, the method logs
        /// the reason for the call ending and triggers a transition to the "leaving"
        /// state.
        private func observeCallEndedEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_CallEnded.self)
                .log(.debug, subsystems: .sfu) { "Call ended with reason: \($0.reason)." }
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    guard let self else { return }
                    transitionOrError(.leaving(context))
                }
                .store(in: disposableBag)
        }

        /// Observes migration events from the SFU (Selective Forwarding Unit) adapter.
        /// If an error or "go away" event with a migration strategy is published, the
        /// method triggers the appropriate transition to handle the migration by
        /// disconnecting and setting the reconnection strategy to `.migrate`.
        private func observeMigrationEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .migrate }
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .migrate
                    log.warning(
                        "Will disconnect because received an SFU error.",
                        subsystems: .webRTC
                    )
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)

            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_GoAway.self)
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .migrate
                    log.warning(
                        """
                        Will disconnect because received instruction to migrate 
                        to another SFU.
                        """,
                        subsystems: .webRTC
                    )
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Observes disconnect events from the SFU (Selective Forwarding Unit) adapter.
        /// If an error event with a `disconnect` reconnection strategy is published,
        /// the method triggers the appropriate transition to handle the disconnect.
        private func observeDisconnectEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .disconnect }
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    guard let self else { return }
                    transitionOrError(.leaving(context))
                }
                .store(in: disposableBag)
        }

        /// Observes the SFU errors looking for the `PARTICIPANT_SIGNAL_LOST`. Once found
        /// triggers fast reconnection based on this: https://www.notion.so/stream-wiki/Improved-Reconnects-and-ICE-connection-handling-2186a5d7f9f680c29236c2c37cfa11a3?source=copy_link#2186a5d7f9f68090bd0ec38594902805
        private func observeParticipantSignalLostEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.error.code == .participantSignalLost }
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .fast(
                        disconnectedSince: .init(),
                        deadline: context.fastReconnectDeadlineSeconds
                    )
                    transitionOrError(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Observes the frequency the HealthCheck responses are flowing via the SFU webSocket. If
        /// at any point we haven't received a HealthCheck response for the `webSocketHealthTimeout`
        /// we consider the WS connection disconnected and try a fast reconnenction.
        private func observeHealthCheckResponses() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_HealthCheckResponse.self)
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    self?.context.lastHealthCheckReceivedAt = .init()
                }
                .store(in: disposableBag)

            DefaultTimer
                .publish(every: 1)
                .compactMap { [weak self] _ in self?.context.lastHealthCheckReceivedAt }
                .filter { [weak self] in
                    guard
                        let timeout = self?.context.webSocketHealthTimeout
                    else {
                        return false
                    }
                    return abs($0.timeIntervalSinceNow) > timeout
                }
                .receive(on: processingQueue)
                .sink { [weak self] lastHealthCheckReceivedAt in
                    guard let self else {
                        return
                    }
                    context.reconnectionStrategy = .fast(
                        disconnectedSince: lastHealthCheckReceivedAt,
                        deadline: context.fastReconnectDeadlineSeconds
                    )
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Observes the preferred reconnection strategy based on error events from the
        /// SFU (Selective Forwarding Unit) adapter. When an error event with a
        /// reconnection strategy is published, the method updates the reconnection
        /// strategy in the context accordingly.
        private func observePreferredReconnectionStrategy() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .map(\.reconnectStrategy)
                .compactMap { [fastReconnectDeadlineSeconds = context.fastReconnectDeadlineSeconds] in
                    WebRTCCoordinator.StateMachine.ReconnectionStrategy(
                        from: $0,
                        fastReconnectDeadlineSeconds: fastReconnectDeadlineSeconds
                    )
                }
                .log(.debug, subsystems: .webRTC) { "Reconnection strategy updated to \($0)." }
                .receive(on: processingQueue)
                .sink { [weak self] in self?.context.reconnectionStrategy = $0 }
                .store(in: disposableBag)
        }

        /// Observes the connection state of both the publisher and subscriber peer
        /// connections. If a disconnection is detected, the method attempts to restart
        /// ICE (Interactive Connectivity Establishment) for both the publisher and
        /// subscriber to restore the connection.
        private func observePeerConnectionState() async {
            guard
                let publisher = await context.coordinator?.stateAdapter.publisher,
                let subscriber = await context.coordinator?.stateAdapter.subscriber
            else {
                return
            }

            publisher
                .disconnectedPublisher
                .log(.debug, subsystems: .webRTC) { "PeerConnection of type: .publisher was disconnected. Will attempt rejoin." }
                .receive(on: processingQueue)
                .sink { [weak self] in
                    guard let self else { return }
                    context.reconnectionStrategy = .rejoin
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)

            subscriber
                .disconnectedPublisher
                .log(.debug, subsystems: .webRTC) { "PeerConnection of type: .subscriber was disconnected. Will attempt rejoin." }
                .receive(on: processingQueue)
                .sink { [weak self] in
                    guard let self else { return }
                    context.reconnectionStrategy = .rejoin
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Configures the collection and delivery of WebRTC statistics by setting up
        /// or updating the `WebRTCStatsReporter` for the current session. This ensures
        /// that statistics such as network quality, peer connection status, and SFU
        /// (Selective Forwarding Unit) adapter performance are tracked and reported
        /// correctly.
        private func configureStatsCollectionAndDelivery() async {
            guard
                let coordinator = context.coordinator
            else {
                return
            }

            let stateAdapter = coordinator.stateAdapter
            let sessionId = await stateAdapter.sessionID

            /// Check if the stats reporter is already associated with the current session.
            if await stateAdapter.statsAdapter?.sessionID != sessionId {
                /// Create a new stats reporter if the session ID does not match.
                let statsReporter = WebRTCStatsAdapter(
                    sessionID: await stateAdapter.sessionID,
                    unifiedSessionID: stateAdapter.unifiedSessionId,
                    isTracingEnabled: await coordinator.stateAdapter.isTracingEnabled,
                    trackStorage: coordinator.stateAdapter.trackStorage
                )

                /// Set the stats reporting interval and associate the reporter with the publisher,
                /// subscriber, and SFU adapter.
                statsReporter.deliveryInterval = await stateAdapter.statsAdapter?.deliveryInterval ?? 0
                statsReporter.publisher = await stateAdapter.publisher
                statsReporter.subscriber = await stateAdapter.subscriber
                statsReporter.sfuAdapter = await stateAdapter.sfuAdapter
                statsReporter.reconnectAttempts = context.reconnectAttempts

                /// Update the state adapter with the new stats reporter.
                await stateAdapter.set(statsAdapter: statsReporter)
            } else {
                /// If the session ID matches, update the existing stats reporter.
                let statsReporter = await stateAdapter.statsAdapter
                statsReporter?.deliveryInterval = await stateAdapter.statsAdapter?.deliveryInterval ?? 0
                statsReporter?.publisher = await stateAdapter.publisher
                statsReporter?.subscriber = await stateAdapter.subscriber
                statsReporter?.sfuAdapter = await stateAdapter.sfuAdapter
                statsReporter?.reconnectAttempts = context.reconnectAttempts
            }
        }

        /// Observes changes in the internet connection status and handles disconnection
        /// logic when the connection becomes unavailable. If the connection is lost,
        /// the method triggers a fast reconnection strategy and sets the disconnection
        /// source to a server-initiated event.
        private func observeInternetConnection() {
            internetConnectionObserver
                .statusPublisher
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .filter { !$0.isAvailable }
                .removeDuplicates()
                .receive(on: processingQueue)
                .sinkTask(storeIn: disposableBag) { [weak self] in
                    guard let self else { return }

                    /// Trace internet connection changes
                    await context
                        .coordinator?
                        .stateAdapter
                        .statsAdapter?
                        .trace(.init(status: $0))

                    /// Set the reconnection strategy to a fast reconnection attempt.
                    context.reconnectionStrategy = .fast(
                        /// Record the disconnection time.
                        disconnectedSince: .init(),
                        /// Set a deadline for reconnection.
                        deadline: context.fastReconnectDeadlineSeconds
                    )

                    /// Set the disconnection source as server-initiated due to a network error.
                    context.disconnectionSource = .serverInitiated(
                        error: .NetworkError("Not available")
                    )

                    log.warning(
                        "Will disconnect because internet connection is down.",
                        subsystems: .webRTC
                    )

                    /// Trigger the transition to a disconnected state or handle the disconnection.
                    transitionOrDisconnect(.disconnected(context))
                }
                .store(in: disposableBag)
        }

        /// Configures the subscription adapter responsible for managing WebRTC
        /// track subscriptions.
        ///
        /// This function initializes the `WebRTCUpdateSubscriptionsAdapter` using
        /// the current participants and incoming video quality settings. It ensures
        /// that subscription updates are properly set up for the active SFU adapter
        /// and session.
        private func configureUpdateSubscriptions() async {
            guard
                let stateAdapter = context.coordinator?.stateAdapter,
                let sfuAdapter = await stateAdapter.sfuAdapter
            else {
                return
            }

            updateSubscriptionsAdapter = .init(
                participantsPublisher: await stateAdapter
                    .$participants
                    .eraseToAnyPublisher(),
                incomingVideoQualitySettingsPublisher: await stateAdapter
                    .$incomingVideoQualitySettings
                    .eraseToAnyPublisher(),
                sfuAdapter: sfuAdapter,
                sessionID: await stateAdapter.sessionID,
                clientCapabilities: await stateAdapter.clientCapabilities
            )
        }
    }
}
