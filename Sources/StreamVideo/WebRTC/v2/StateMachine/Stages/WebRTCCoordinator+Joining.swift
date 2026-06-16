//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a joining stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the joining stage.
    /// - Returns: A `JoiningStage` instance representing the joining state of
    ///   the WebRTC coordinator.
    static func joining(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        JoiningStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the joining stage in the WebRTC coordinator state machine.
    final class JoiningStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {

        @Injected(\.audioStore) private var audioStore

        private let disposableBag = DisposableBag()
        private let startTime = Date()
        private var telemetryReporter: JoinedStateTelemetryReporter = .init()
        private var webSocketJoinTelemetryReporter: WebSocketJoinTelemetryReporter = .init()

        /// Initializes a new instance of `JoiningStage`.
        /// - Parameter context: The context for the joining stage.
        init(
            _ context: Context
        ) {
            super.init(id: .joining, context: context)
        }

        /// Performs the transition from a previous stage to this joining stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `JoiningStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: `.connected`, `.fastReconnected`,
        ///   `.migrated`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connected where context.isRejoiningFromSessionID != nil:
                telemetryReporter.flowType = .rejoin
                executeRejoining()
                return self
            case .connected:
                telemetryReporter.flowType = .regular
                execute(isFastReconnecting: false)
                return self
            case .fastReconnected:
                telemetryReporter.flowType = .fast
                execute(isFastReconnecting: true)
                return self
            case .migrated:
                telemetryReporter.flowType = .migrate
                executeMigration()
                return self
            default:
                return nil
            }
        }

        /// Cancels in-flight join, rejoin, or migration work before leaving
        /// `.joining`.
        override func willTransitionAway() {
            super.willTransitionAway()
            disposableBag.removeAll()
        }

        /// Executes the joining process.
        /// - Parameter isFastReconnecting: A flag indicating if this is a fast
        ///   reconnection.
        private func execute(
            isFastReconnecting: Bool
        ) {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let coordinator = context.coordinator,
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(
                            capabilities: coordinator.stateAdapter.clientCapabilities.map(\.rawValue)
                        )
                        .buildRequest(
                            with: isFastReconnecting ? .fastReconnect : .default,
                            coordinator: coordinator,
                            publisherSdp: try await buildSessionDescription(
                                peerConnectionType: .publisher,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: isFastReconnecting
                            ),
                            subscriberSdp: try await buildSessionDescription(
                                peerConnectionType: .subscriber,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: isFastReconnecting
                            ),
                            reconnectAttempt: context.reconnectAttempts,
                            publisher: await coordinator.stateAdapter.publisher
                        )
                    )

                    if !isFastReconnecting {
                        try await beginWebSocketJoin(
                            coordinator: coordinator
                        )
                    }

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter,
                        isFastReconnecting: isFastReconnecting
                    )

                    try Task.checkCancellation()

                    if isFastReconnecting {
                        await coordinator.stateAdapter.publisher?.restartICE()
                    }

                    await transitionToNextStage(
                        context,
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )
                } catch {
                    context.reconnectionStrategy = context
                        .reconnectionStrategy
                        .next
                    transitionDisconnectOrError(error)
                }
            }
        }

        /// Executes the migration process.
        private func executeMigration() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let coordinator = context.coordinator,
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(
                            capabilities: coordinator.stateAdapter.clientCapabilities.map(\.rawValue)
                        )
                        .buildRequest(
                            with: .migration(fromHostname: context.migratingFromSFU),
                            coordinator: coordinator,
                            publisherSdp: try await buildSessionDescription(
                                peerConnectionType: .publisher,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: false
                            ),
                            subscriberSdp: try await buildSessionDescription(
                                peerConnectionType: .subscriber,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: false
                            ),
                            reconnectAttempt: context.reconnectAttempts,
                            publisher: context.previousSessionPublisher
                        )
                    )

                    context.reconnectAttempts += 1

                    try await beginWebSocketJoin(
                        coordinator: coordinator
                    )

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter,
                        isFastReconnecting: false
                    )

                    await transitionToNextStage(
                        context,
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )
                } catch {
                    context.reconnectionStrategy = .rejoin
                    transitionDisconnectOrError(error)
                }
            }
        }

        /// Executes the rejoining process.
        private func executeRejoining() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let isRejoiningFromSessionID = context.isRejoiningFromSessionID,
                        let coordinator = context.coordinator,
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    else {
                        throw ClientError(
                            "WebRCTCoordinator instance not available."
                        )
                    }

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(
                            capabilities: coordinator.stateAdapter.clientCapabilities.map(\.rawValue)
                        )
                        .buildRequest(
                            with: .rejoin(fromSessionID: isRejoiningFromSessionID),
                            coordinator: coordinator,
                            publisherSdp: try await buildSessionDescription(
                                peerConnectionType: .publisher,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: false
                            ),
                            subscriberSdp: try await buildSessionDescription(
                                peerConnectionType: .subscriber,
                                coordinator: coordinator,
                                sfuAdapter: sfuAdapter,
                                isFastReconnecting: false
                            ),
                            reconnectAttempt: context.reconnectAttempts,
                            publisher: context.previousSessionPublisher
                        )
                    )
                    context.reconnectAttempts += 1

                    try await beginWebSocketJoin(
                        coordinator: coordinator
                    )

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter,
                        isFastReconnecting: false
                    )

                    await transitionToNextStage(
                        context,
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )
                } catch {
                    transitionDisconnectOrError(error)
                }
            }
        }

        /// Builds the subscriber session description.
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        ///   - isFastReconnecting: A flag indicating if this is a fast
        ///     reconnection.
        ///   - publisher: The RTC peer connection coordinator for publishing.
        /// - Returns: The subscriber session description as a string.
        private func buildSessionDescription(
            peerConnectionType: PeerConnectionType,
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter,
            isFastReconnecting: Bool
        ) async throws -> String {
            try await RTCTemporaryPeerConnection(
                peerConnectionType: peerConnectionType,
                coordinator: coordinator,
                sfuAdapter: sfuAdapter
            ).createOffer().sdp
        }

        /// Performs the SFU join process after the join request is sent.
        ///
        /// `WSJoin` telemetry is completed as soon as the SFU `JoinResponse`
        /// is received. Everything after that response, including
        /// peer-connection setup and media readiness, belongs to later stages.
        /// The remaining work applies the SFU response, configures peer
        /// connections when needed, waits for the SFU socket to connect, and
        /// reports the overall join telemetry.
        ///
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        private func join(
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter,
            isFastReconnecting: Bool
        ) async throws {
            // Fast reconnects refresh the WebSocket transparently and must not
            // emit join-lifecycle client events.
            guard !isFastReconnecting else {
                try await performJoin(
                    coordinator: coordinator,
                    sfuAdapter: sfuAdapter,
                    isFastReconnecting: true
                )
                return
            }

            try await performJoin(
                coordinator: coordinator,
                sfuAdapter: sfuAdapter,
                isFastReconnecting: false
            )
        }

        /// Waits for the SFU join response, then prepares peer connections.
        ///
        /// The `JoinResponse` wait is the only part included in `WSJoin`
        /// elapsed time. Subsequent setup still happens here, but is reported
        /// by peer-connection and first-frame client events.
        ///
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        private func performJoin(
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter,
            isFastReconnecting: Bool
        ) async throws {
            if let eventObserver = context.sfuEventObserver {
                eventObserver.sfuAdapter = sfuAdapter
            } else {
                context.sfuEventObserver = .init(
                    sfuAdapter: sfuAdapter,
                    stateAdapter: coordinator.stateAdapter
                )
            }

            try Task.checkCancellation()

            /// We update the reconnectAttempts on the adapter so that we can correctly
            /// create the trace prefixes for peerConnections.
            if let statsAdapter = await coordinator.stateAdapter.statsAdapter {
                statsAdapter.reconnectAttempts = context.reconnectAttempts
            }

            try Task.checkCancellation()

            // We create an event bucket in which we collect all SFU events
            // that will be received until the moment our PeerConnections have
            // been setup.
            let subscriberEventBucket = ConsumableBucket(
                sfuAdapter
                    .publisher
                    .eraseToAnyPublisher()
            )

            try Task.checkCancellation()

            let joinResponse = try await observeSFUResponse(
                sfuAdapter: sfuAdapter,
                isFastReconnecting: isFastReconnecting
            )

            try Task.checkCancellation()

            await coordinator
                .stateAdapter
                .set(publishOptions: .init(joinResponse.publishOptions))

            try Task.checkCancellation()

            let participants = joinResponse
                .callState
                .participants
                .map { $0.toCallParticipant() }
                /// We remove the existing user (if we are rejoining) in order to avoid showing a stale
                /// video tile in the Call.
                .filter { $0.sessionId != context.isRejoiningFromSessionID }
                .reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }

            await coordinator
                .stateAdapter
                .enqueue { _ in participants }

            try Task.checkCancellation()

            sfuAdapter.sendHealthCheck()

            try Task.checkCancellation()

            if !isFastReconnecting {
                try await withThrowingTaskGroup(of: Void.self) { [weak self, context] group in
                    group.addTask { [context] in
                        /// Configures the audio session for the current call using the provided
                        /// join source. This ensures the session setup reflects whether the
                        /// join was triggered in-app or via CallKit and applies the correct
                        /// audio routing and category.
                        try await coordinator.stateAdapter.configureAudioSession(
                            source: context.joinSource
                        )
                    }

                    group.addTask { [weak self, context] in
                        /// Before we move on configuring the PeerConnections we need to ensure
                        /// that the audioSession has been activated and configured correctly.
                        ///
                        /// When the join was initiated from CallKit, activation only happens
                        /// after the call has fully joined and the pending answer action has
                        /// been fulfilled, so waiting here would always time out. We skip the
                        /// wait and let CallKit's later activation start audio once it arrives.
                        if case .callKit = context.joinSource {
                            // No-op: CallKit activates the session post-join.
                        } else {
                            await self?.ensureAudioSessionIsReady()
                        }

                        /// Configures all peer connections after the audio session is ready.
                        /// Ensures signaling, media, and routing are correctly established for
                        /// all tracks as part of the join process.
                        try await coordinator.stateAdapter.configurePeerConnections()
                    }

                    try await group.waitForAll()
                }

                try Task.checkCancellation()

                // Now that the peer connections exist, start reporting the
                // PeerConnectionConnect client event pairs by observing their
                // connection state until each resolves.
                await startPeerConnectionConnectReporting(coordinator: coordinator)

                // Once our PeerConnections have been created we replay the
                // buffered SFU events that may have arrived before the
                // subscriber stack was ready to observe them.
                //
                // This is especially important when we join a call where
                // another participant is already publishing audio. In that
                // case the SFU can send both a subscriber offer and the
                // associated subscriber ICE trickles before the subscriber
                // peer connection and ICE adapter are fully configured.
                sfuAdapter.consume(
                    Stream_Video_Sfu_Event_SubscriberOffer.self,
                    bucket: subscriberEventBucket,
                    flush: false
                )

                sfuAdapter.consume(
                    Stream_Video_Sfu_Models_ICETrickle.self,
                    bucket: subscriberEventBucket,
                    flush: true
                )

                try Task.checkCancellation()

                // Start subscription updates before entering joined/PC readiness
                // so SFU can react with subscriber offers as early as possible.
                await configureUpdateSubscriptions(sfuAdapter)
            }

            try Task.checkCancellation()

            try await coordinator
                .stateAdapter
                .publisher?
                .didUpdateCallSettings(await coordinator.stateAdapter.callSettings)

            try Task.checkCancellation()

            try await context.authenticator.waitForConnect(on: sfuAdapter)

            try Task.checkCancellation()

            context.fastReconnectDeadlineSeconds = TimeInterval(
                joinResponse.fastReconnectDeadlineSeconds
            )

            try Task.checkCancellation()
        }

        /// Waits for early audio-session readiness before peer-connection setup.
        ///
        /// This method runs in `JoiningStage` right after audio-session
        /// configuration and just before `configurePeerConnections()`.
        ///
        /// Why this exists:
        /// - The join flow can race with audio-session activation/route
        ///   propagation (especially when control is handed back from CallKit).
        /// - Creating peer connections before audio is active and routed can
        ///   increase the chance of stale/no-audio media setup.
        ///
        /// How it behaves:
        /// - It waits for `context.audioSessionWatchdog.publisher` to emit
        ///   `true` (audio session active and route non-empty).
        /// - The wait is bounded by `timeout`; on timeout it logs a warning and
        ///   intentionally continues the join flow.
        /// - It always emits a trace with the watchdog's current readiness
        ///   snapshot so diagnostics can distinguish "ready" vs "still
        ///   preparing" join paths.
        ///
        /// This method is intentionally best-effort: we prefer joining with a
        /// degraded readiness signal over blocking join completion indefinitely.
        ///
        /// - Parameter timeout: Maximum seconds to wait for the watchdog to
        ///   report readiness before continuing.
        private func ensureAudioSessionIsReady(
            timeout: TimeInterval = WebRTCConfiguration.timeout.audioSessionConfigurationCompletion
        ) async {
            do {
                _ = try await context
                    .audioSessionWatchdog
                    .publisher
                    .filter { $0 }
                    .nextValue(timeout: timeout)
            } catch {
                log.warning("AudioSession isn't ready after \(timeout) seconds. Will continue with the join flow.")
            }

            await context.coordinator?.stateAdapter.trace(.init(context.audioSessionWatchdog))
        }

        /// Configures the adapter responsible for updating track subscriptions.
        ///
        /// This can be invoked as soon as participant state and peer connections are
        /// available. The adapter is retained by the state adapter so updates continue
        /// across stage transitions.
        func configureUpdateSubscriptions(_ sfuAdapter: SFUAdapter) async {
            guard let stateAdapter = context.coordinator?.stateAdapter else {
                transitionDisconnectOrError(ClientError())
                return
            }

            context.updateSubscriptionsAdapter?.stopObservation()
            context.updateSubscriptionsAdapter = nil

            context.updateSubscriptionsAdapter = await .init(
                participantsPublisher: stateAdapter.$participants.eraseToAnyPublisher(),
                incomingVideoQualitySettingsPublisher: stateAdapter.$incomingVideoQualitySettings
                    .eraseToAnyPublisher(),
                sfuAdapter: sfuAdapter,
                sessionID: stateAdapter.sessionID,
                clientCapabilities: stateAdapter.clientCapabilities
            )

            // If there is a publishing participant (other than ourselves) we
            // update subscription just for this user, to warm up the subscriber
            // peerConnection. In that way we try to make subscriber pc
            // ready as soon as possible when the call transitions to joined
            let sessionID = await stateAdapter.sessionID
            if let firstPublishingParticipant = await stateAdapter.participants.values
                .first(where: { ($0.hasAudio || $0.hasVideo) && $0.sessionId != sessionID }) {
                context.updateSubscriptionsAdapter?.updateSubscriptions(
                    for: [firstPublishingParticipant],
                    incomingVideoQualitySettings: .none,
                    trackTypes: [.audio, .video]
                )
            }
        }

        /// Starts observing the publisher and subscriber peer connections so the
        /// ``ClientEventStage/peerConnectionConnect`` event pairs are reported as
        /// each connection resolves.
        ///
        /// A connection that never starts negotiating (for example the publisher
        /// of a subscribe-only viewer) emits nothing, which the backend treats as
        /// "publish not attempted".
        private func startPeerConnectionConnectReporting(
            coordinator: WebRTCCoordinator
        ) async {
            let stateAdapter = coordinator.stateAdapter
            let details = ClientEventStageDetails(
                sfuId: context.currentSFU,
                callSessionId: context.initialJoinCallResponse?.call.session?.id,
                coordinatorConnectId: context.coordinatorConnectId
            )
            let wasPreviouslyConnected = context.reconnectAttempts > 0

            // Stop any reporters left over from a previous attempt before
            // starting fresh observation for this one.
            context.peerConnectionConnectReporters.forEach { $0.stop() }
            context.peerConnectionConnectReporters = []

            let peerConnections: [(PeerConnectionType, RTCPeerConnectionCoordinator?)] = [
                (.publisher, await stateAdapter.publisher),
                (.subscriber, await stateAdapter.subscriber)
            ]

            context.peerConnectionConnectReporters = peerConnections.compactMap { peerType, peerConnection in
                guard let peerConnection else { return nil }
                return WebRTCPeerConnectionConnectReporter(
                    peerConnectionType: peerType,
                    statePublisher: peerConnection.connectionStatePublisher,
                    reporter: coordinator.clientEventReporter,
                    wasPreviouslyConnected: wasPreviouslyConnected,
                    details: details
                )
            }
        }

        private func transitionToNextStage(
            _ context: Context,
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter
        ) async {
            switch context.joinPolicy {
            case .default:
                await telemetryReporter.reportTelemetry(
                    sessionId: await coordinator.stateAdapter.sessionID,
                    unifiedSessionId: coordinator.stateAdapter.unifiedSessionId,
                    sfuAdapter: sfuAdapter
                )
                reportJoinCompletion()
                transitionOrDisconnect(.joined(self.context))

            case .peerConnectionReadinessAware:
                transitionOrDisconnect(
                    .peerConnectionPreparing(
                        self.context,
                        telemetryReporter: telemetryReporter
                    )
                )
            }
        }

        /// Starts `WSJoin` telemetry for the active SFU join request.
        ///
        /// Fast reconnects skip this because they refresh the SFU socket
        /// transparently and must not emit join-lifecycle client events.
        ///
        /// - Parameter coordinator: Coordinator that owns the reporter and
        ///   state adapter for this attempt.
        private func beginWebSocketJoin(
            coordinator: WebRTCCoordinator
        ) async throws {
            webSocketJoinTelemetryReporter.configure(
                stateAdapter: coordinator.stateAdapter,
                clientEventReporter: coordinator.clientEventReporter
            )

            try Task.checkCancellation()

            await webSocketJoinTelemetryReporter.begin(
                sfuId: context.currentSFU,
                callSessionId: context.initialJoinCallResponse?.call.session?.id,
                coordinatorConnectId: context.coordinatorConnectId
            )
        }

        /// Resolves the current `WSJoin` event pair.
        ///
        /// - Parameter error: Optional error from waiting for the SFU
        ///   `JoinResponse`; `nil` marks the attempt as successful.
        private func completeWebSocketJoin(
            _ error: Error?
        ) async {
            if let error {
                await webSocketJoinTelemetryReporter.fail(
                    retryCount: Int(context.reconnectAttempts),
                    error: error
                )
            } else {
                await webSocketJoinTelemetryReporter.complete(
                    retryCount: Int(context.reconnectAttempts)
                )
            }
        }

        /// Waits for the SFU `JoinResponse` and resolves `WSJoin` telemetry.
        ///
        /// The response is the success boundary for `WSJoin`. Fast reconnects
        /// still wait for the response but do not emit client-event telemetry.
        ///
        /// - Parameters:
        ///   - sfuAdapter: SFU adapter that publishes join responses.
        ///   - isFastReconnecting: Whether this is a transparent fast
        ///     reconnect.
        /// - Returns: The SFU join response.
        private func observeSFUResponse(
            sfuAdapter: SFUAdapter,
            isFastReconnecting: Bool
        ) async throws -> Stream_Video_Sfu_Event_JoinResponse {
            do {
                let joinResponse = try await sfuAdapter
                    .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
                    .nextValue(timeout: WebRTCConfiguration.timeout.join)

                if !isFastReconnecting {
                    await completeWebSocketJoin(nil)
                }

                return joinResponse
            } catch {
                if !isFastReconnecting {
                    await completeWebSocketJoin(error)
                }

                throw error
            }
        }
    }
}
