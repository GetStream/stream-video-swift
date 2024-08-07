//
//  WebRTCCoordinator+Joined.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
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

                    cleanUpPreviousSessionIfRequired()
                    observeInternetConnection()

                    await observeForSubscriptionUpdates()
                    await observeConnection()
                    await observeMigrationEvent()
                    await observeDisconnectEvent()
                    await observePreferredReconnectionStrategy()
                    await observeCallSettingsUpdates()
                    await observePeerConnectionState()
                    await configureStatsCollectionAndDelivery()

                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }

        // MARK: -

        private func cleanUpPreviousSessionIfRequired() {
            let publisher = context.previousSessionPublisher
            let subscriber = context.previousSessionSubscriber
            context.previousSessionPublisher = nil
            context.previousSessionSubscriber = nil
            context.previousSFUAdapter = nil

            guard publisher != nil || subscriber != nil else {
                return
            }

            Task {
                do {
                    try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                    publisher?.close()
                    subscriber?.close()
                } catch {
                    transitionErrorOrLog(error)
                }
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
                    context.disconnectionSource = source
                    if let sfuError = (source.serverError?.underlyingError as? Stream_Video_Sfu_Models_Error) {
                        context.reconnectionStrategy = sfuError.shouldRetry
                        ? .fast(
                            disconnectedSince: .init(),
                            deadline: context.fastReconnectDeadlineSeconds
                        )
                        : .rejoin
                    }

                    do {
                        try transition?(
                            .disconnected(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
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
                    do {
                        context.reconnectionStrategy = .migrate
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)

            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_GoAway.self)
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        context.reconnectionStrategy = .migrate
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
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
                    do {
                        try transition?(
                            .leaving(context)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observePreferredReconnectionStrategy() async {
            let sfuAdapter = await context.coordinator?.stateAdapter.sfuAdapter
            sfuAdapter?
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .map { $0.reconnectStrategy }
                .compactMap { [weak self] in self?.reconnectionStrategyToUse($0) }
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
                .map { Array($0.values) }
                .map { values in values.filter { $0.id != sessionID } }
                .map { values in values.flatMap { $0.trackSubscriptionDetails }}
                .sink { [weak sfuAdapter, disposableBag, weak self] tracks in
                    Task { [weak self, weak sfuAdapter] in
                        guard self != nil, let sfuAdapter else { return }
                        do {
                            try Task.checkCancellation()
                            try await sfuAdapter.updateSubscriptions(
                                tracks: tracks,
                                for: sessionID
                            )
                        } catch {
                            self?.transitionErrorOrLog(error)
                        }
                    }
                    .store(in: disposableBag, key: "update-subscriptions")
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
                .sink { [disposableBag, weak self] callSettings in
                    Task { [weak self] in
                        do {
                            guard
                                let publisher = await self?.context.coordinator?.stateAdapter.publisher
                            else {
                                throw ClientError("PeerConnection haven't been setUp for publishing.")
                            }
                            try await publisher.didUpdateCallSettings(callSettings)
                            log.debug("Publisher callSettings updated.")
                        } catch {
                            self?.transitionErrorOrLog(error)
                        }
                    }.store(in: disposableBag, key: "callSettings-updates")
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
                    do {
                        context.reconnectionStrategy = .fast(
                            disconnectedSince: .init(),
                            deadline: context.fastReconnectDeadlineSeconds
                        )
                        context.disconnectionSource = .serverInitiated(error: .NetworkError("Not available"))
                        try transition?(
                            .disconnected(context)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func reconnectionStrategyToUse(
            _ reconnectionStrategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy
        ) -> WebRTCCoordinator.StateMachine.ReconnectionStrategy {
            switch reconnectionStrategy {
            case .fast:
                return .fast(
                    disconnectedSince: Date(),
                    deadline: context.fastReconnectDeadlineSeconds
                )

            case .rejoin:
                return .rejoin

            case .migrate:
                return .migrate

            case .disconnect:
                return .disconnected

            default:
                return .rejoin
            }
        }
    }
}

