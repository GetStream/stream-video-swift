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

        /// Performs the join process.
        /// The steps we should follow are:
        /// - Wait for the joinResponse.
        /// - Extract the publishOptions from the joinResponse and update the WebRTCStateAdapter.
        /// - If we are not fastReconnecting, configure our peerConnections (and restore screenSharing)
        /// if required.
        /// - Extract participants from the joinResponse and update the WebRTCStateAdapter.
        /// - Extract callSettings from the joinResponse and update the WebRTCStateAdapter.
        /// - Extract fastReconnectionDeadline from the joinResponse and update the context.
        /// - Wait for the webSocket state to become `.connected`.
        /// - Report telemetry.
        ///
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        private func join(
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

            let joinResponse = try await sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
                .nextValue(timeout: WebRTCConfiguration.timeout.join)

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

                    group.addTask { [weak self] in
                        /// Before we move on configuring the PeerConnections we need to ensure
                        /// that the audioSession has been:
                        /// - released from CallKit (if our source was CallKit)
                        /// - activated and configured correctly
                        try await self?.ensureAudioSessionIsReady()

                        /// Configures all peer connections after the audio session is ready.
                        /// Ensures signaling, media, and routing are correctly established for
                        /// all tracks as part of the join process.
                        try await coordinator.stateAdapter.configurePeerConnections()
                    }

                    try await group.waitForAll()
                }

                try Task.checkCancellation()

                // Once our PeerConnection have been created we consume the
                // eventBucket we created above in order to re-apply any event
                // that our PeerConnections missed during the initialisation.
                //
                // Specifically, below we are consuming any SubscriberOffer event
                // that has being received before our Subscriber was ready to
                // process it. This scenario is possible to occur if we join
                // a call where another user is already publishing audio.
                sfuAdapter.consume(
                    Stream_Video_Sfu_Event_SubscriberOffer.self,
                    bucket: subscriberEventBucket
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

        /// Waits until the audio session is fully ready for call setup.
        ///
        /// The function waits in parallel for:
        /// - `audioStore` to report `isActive == true`
        /// - `audioStore` to report a non-empty `currentRoute`
        /// within the provided `timeout`.
        ///
        /// - Parameter timeout: Maximum number of seconds to wait for both
        ///   conditions before failing.
        /// - Throws: If either readiness condition does not arrive before
        ///   `timeout`.
        private func ensureAudioSessionIsReady() async throws {
            try await withThrowingTaskGroup(of: Void.self) { [audioStore] group in
                group.addTask {
                    _ = try await audioStore
                        .publisher(\.isActive)
                        .filter { $0 }
                        .nextValue(timeout: WebRTCConfiguration.timeout.audioSessionConfigurationCompletion)
                }

                group.addTask {
                    _ = try await audioStore
                        .publisher(\.currentRoute)
                        .filter { $0 != .empty }
                        .nextValue(timeout: WebRTCConfiguration.timeout.audioSessionConfigurationCompletion)
                }

                try await group.waitForAll()
            }
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

            // If there is a publishing participant we update subscriptions
            // just for this user, to warm up the subscriber
            // peerConnection. In that way we try to make subscriber pc
            // ready as soon as possible when the call transitions to joined
            if let firstPublishingParticipant = await stateAdapter.participants.values
                .first(where: { $0.hasAudio || $0.hasVideo }) {
                context.updateSubscriptionsAdapter?.updateSubscriptions(
                    for: [firstPublishingParticipant],
                    incomingVideoQualitySettings: .none,
                    trackTypes: [.audio, .video]
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
    }
}
