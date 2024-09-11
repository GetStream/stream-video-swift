//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func joined(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        JoinedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class JoinedStage: WebRTCCoordinator.StateMachine.Stage {

        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private let disposableBag = DisposableBag()

        init(
            _ context: Context
        ) {
            super.init(id: .joined, context: context)
        }

        deinit {
            disposableBag.removeAll()
        }

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

        override func didTransitionAway() {
            disposableBag.removeAll()
        }

        private func execute() {
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard
                        context.coordinator != nil
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    // We set the reconnectionStrategy to rejoin as default.
                    context.reconnectionStrategy = .rejoin

                    let migrationStatusObserver = context.migrationStatusObserver
                    let previousSFUAdapter = context.previousSFUAdapter
                    await cleanUpPreviousSessionIfRequired()

                    try await observeMigrationStatusIfRequired(
                        migrationStatusObserver,
                        previousSFUAdapter: previousSFUAdapter
                    )

                    observeInternetConnection()

                    await observeForSubscriptionUpdates()
                    await observeConnection()
                    await observeCallEndedEvent()
                    await observeMigrationEvent()
                    await observeDisconnectEvent()
                    await observePreferredReconnectionStrategy()
                    await observeCallSettingsUpdates()
                    await observePeerConnectionState()
                    await configureStatsCollectionAndDelivery()
                } catch {
                    context.flowError = error
                    disconnect()
                }
            }
        }

        // MARK: -

        private func cleanUpPreviousSessionIfRequired() async {
            let publisher = context.previousSessionPublisher
            let subscriber = context.previousSessionSubscriber
            let previousSFUAdapter = context.previousSFUAdapter
            context.previousSessionPublisher = nil
            context.previousSessionSubscriber = nil
            context.previousSFUAdapter = nil
            context.migratingFromSFU = ""
            context.isRejoiningFromSessionID = nil
            context.migrationStatusObserver = nil
            publisher?.close()
            subscriber?.close()
            if context.migrationStatusObserver != nil {
                await previousSFUAdapter?.disconnect()
            }
        }

        private func observeMigrationStatusIfRequired(
            _ migrationStatusObserver: MigrationStatusObserver?,
            previousSFUAdapter: SFUAdapter?
        ) async throws {
            if let migrationStatusObserver = migrationStatusObserver {
                let task = Task {
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
                task.store(in: disposableBag)
                _ = try await task.value
            }
        }

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
                .sink { [weak self] (source: WebSocketConnectionState.DisconnectionSource) in
                    guard let self else { return }
                    disposableBag.removeAll()
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
                            "Will disconnect because ws connection state changed to disconnecting/disconnected with source:\(source)."
                        )
                    disconnect()
                }
                .store(in: disposableBag)
        }

        private func observeCallEndedEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_CallEnded.self)
                .log(.debug, subsystems: .sfu) { "Call ended with reason: \($0.reason)." }
                .sink { [weak self] _ in
                    guard let self else { return }
                    transitionOrError(.leaving(context))
                }
                .store(in: disposableBag)
        }

        private func observeMigrationEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .migrate }
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .migrate
                    log.warning("Will disconnect because received an SFU error.", subsystems: .webRTC)
                    disconnect()
                }
                .store(in: disposableBag)

            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_GoAway.self)
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .migrate
                    log.warning("Will disconnect because received instruction to migrate to another SFU.", subsystems: .webRTC)
                    disconnect()
                }
                .store(in: disposableBag)
        }

        private func observeDisconnectEvent() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .disconnect }
                .sink { [weak self] _ in
                    guard let self else { return }
                    transitionOrError(.leaving(context))
                }
                .store(in: disposableBag)
        }

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
                .sink { [weak self] in self?.context.reconnectionStrategy = $0 }
                .store(in: disposableBag)
        }

        private func observeForSubscriptionUpdates() async {
            guard
                let stateAdapter = context.coordinator?.stateAdapter,
                let sfuAdapter = await stateAdapter.sfuAdapter
            else {
                return
            }
            let sessionID = await stateAdapter.sessionID
            await stateAdapter
                .$participants
                .removeDuplicates()
                .log(.debug) { "\($0.count) Participants updated and we update subscriptions now." }
                .map { participants in
                    Array(participants.values)
                        .filter { $0.id != sessionID }
                        .flatMap(\.trackSubscriptionDetails)
                }
                .sinkTask(storeIn: disposableBag) { [weak self] tracks in
                    guard let self else { return }
                    do {
                        try Task.checkCancellation()
                        try await sfuAdapter.updateSubscriptions(
                            tracks: tracks,
                            for: sessionID
                        )
                    } catch {
                        transitionDisconnectOrError(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observeCallSettingsUpdates() async {
            await context
                .coordinator?
                .stateAdapter
                .$callSettings
                .compactMap { $0 }
                .removeDuplicates()
                .log(.debug, subsystems: .webRTC) {
                    """
                    CallSettings updated
                        audioOn: \($0.audioOn)
                        videoOn: \($0.videoOn)
                        audioOutputOn: \($0.audioOutputOn)
                    """
                }
                .sinkTask(storeIn: disposableBag) { [weak self] callSettings in
                    guard let self else { return }
                    do {
                        guard
                            let publisher = await context.coordinator?.stateAdapter.publisher
                        else {
                            log.warning(
                                "PeerConnection haven't been setUp for publishing.",
                                subsystems: .webRTC
                            )
                            return
                        }
                        try await publisher.didUpdateCallSettings(callSettings)
                        log.debug("Publisher callSettings updated.", subsystems: .webRTC)
                    } catch {
                        context.flowError = error
                        log.warning("Will disconnect because failed to update callSettings on publisher.", subsystems: .webRTC)
                        disconnect()
                    }
                }
                .store(in: disposableBag)
        }

        private func observePeerConnectionState() async {
            guard
                let publisher = await context.coordinator?.stateAdapter.publisher,
                let subscriber = await context.coordinator?.stateAdapter.subscriber
            else {
                return
            }
            publisher
                .disconnectedPublisher
                .log(.debug, subsystems: .webRTC) {
                    """
                    PeerConnection of type:\($0) was disconnected. Will attempt
                    restarting ICE.
                    """
                }
                .sink { [weak publisher] in publisher?.restartICE() }
                .store(in: disposableBag)

            subscriber
                .disconnectedPublisher
                .log(.debug, subsystems: .webRTC) {
                    """
                    PeerConnection of type:\($0) was disconnected. Will attempt
                    restarting ICE.
                    """
                }
                .sink { [weak subscriber] in subscriber?.restartICE() }
                .store(in: disposableBag)
        }

        private func configureStatsCollectionAndDelivery() async {
            guard
                let coordinator = context.coordinator
            else {
                return
            }
            let stateAdapter = coordinator.stateAdapter

            let statsReporter = WebRTCStatsReporter(
                sessionID: await stateAdapter.sessionID
            )
            await stateAdapter.set(statsReporter)

            statsReporter.interval = await stateAdapter.statsReporter?.interval ?? 0
            statsReporter.publisher = await stateAdapter.publisher
            statsReporter.subscriber = await stateAdapter.subscriber
            statsReporter.sfuAdapter = await stateAdapter.sfuAdapter
        }

        private func observeInternetConnection() {
            internetConnectionObserver
                .$status
                .receive(on: DispatchQueue.main)
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .filter { !$0.isAvailable }
                .removeDuplicates()
                .sink { [weak self] _ in
                    guard let self else { return }
                    context.reconnectionStrategy = .fast(
                        disconnectedSince: .init(),
                        deadline: context.fastReconnectDeadlineSeconds
                    )
                    context.disconnectionSource = .serverInitiated(
                        error: .NetworkError("Not available")
                    )
                    log.warning("Will disconnect because internet connection is down.", subsystems: .webRTC)
                    disconnect()
                }
                .store(in: disposableBag)
        }

        private func disconnect() {
            disposableBag.removeAll()
            transitionOrError(.disconnected(context))
        }
    }
}
