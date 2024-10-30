//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

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
        @unchecked Sendable
    {
        private let disposableBag = DisposableBag()

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
                executeRejoining()
                return self
            case .connected:
                execute(isFastReconnecting: false)
                return self
            case .fastReconnected:
                execute(isFastReconnecting: true)
                return self
            case .migrated:
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
            Task { [weak self] in
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

                    if !isFastReconnecting {
                        try await coordinator.stateAdapter.configurePeerConnections()
                    }

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory()
                            .buildRequest(
                                with: isFastReconnecting ? .fastReconnect : .default,
                                coordinator: coordinator,
                                subscriberSdp: try await buildSubscriberSessionDescription(
                                    coordinator: coordinator,
                                    sfuAdapter: sfuAdapter,
                                    isFastReconnecting: isFastReconnecting,
                                    publisher: await coordinator.stateAdapter.publisher
                                ),
                                reconnectAttempt: context.reconnectAttempts,
                                publisher: await coordinator.stateAdapter.publisher
                            )
                    )

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    try Task.checkCancellation()

                    if isFastReconnecting {
                        await coordinator.stateAdapter.publisher?.restartICE()
                        await coordinator.stateAdapter.subscriber?.restartICE()
                    }

                    transitionOrDisconnect(.joined(context))
                } catch {
                    context.reconnectionStrategy = context
                        .reconnectionStrategy
                        .next
                    transitionDisconnectOrError(error)
                }
            }
            .store(in: disposableBag)
        }

        /// Executes the migration process.
        private func executeMigration() {
            Task { [weak self] in
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

                    try await coordinator.stateAdapter.configurePeerConnections()

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory()
                            .buildRequest(
                                with: .migration(fromHostname: context.migratingFromSFU),
                                coordinator: coordinator,
                                subscriberSdp: try await buildSubscriberSessionDescription(
                                    coordinator: coordinator,
                                    sfuAdapter: sfuAdapter,
                                    isFastReconnecting: false,
                                    publisher: await coordinator.stateAdapter.publisher
                                ),
                                reconnectAttempt: context.reconnectAttempts,
                                publisher: await coordinator.stateAdapter.publisher
                            )
                    )

                    context.reconnectAttempts += 1

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    transitionOrDisconnect(.joined(context))
                } catch {
                    context.reconnectionStrategy = .rejoin
                    transitionDisconnectOrError(error)
                }
            }
            .store(in: disposableBag)
        }

        /// Executes the rejoining process.
        private func executeRejoining() {
            Task { [weak self] in
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

                    try await coordinator.stateAdapter.configurePeerConnections()

                    try Task.checkCancellation()

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory()
                            .buildRequest(
                                with: .rejoin(fromSessionID: isRejoiningFromSessionID),
                                coordinator: coordinator,
                                subscriberSdp: try await buildSubscriberSessionDescription(
                                    coordinator: coordinator,
                                    sfuAdapter: sfuAdapter,
                                    isFastReconnecting: false,
                                    publisher: coordinator.stateAdapter.publisher
                                ),
                                reconnectAttempt: context.reconnectAttempts,
                                publisher: coordinator.stateAdapter.publisher
                            )
                    )
                    context.reconnectAttempts += 1

                    try Task.checkCancellation()

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    transitionOrDisconnect(.joined(context))
                } catch {
                    transitionDisconnectOrError(error)
                }
            }
            .store(in: disposableBag)
        }

        /// Builds the subscriber session description.
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        ///   - isFastReconnecting: A flag indicating if this is a fast
        ///     reconnection.
        ///   - publisher: The RTC peer connection coordinator for publishing.
        /// - Returns: The subscriber session description as a string.
        private func buildSubscriberSessionDescription(
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter,
            isFastReconnecting: Bool,
            publisher: RTCPeerConnectionCoordinator?
        ) async throws -> String {
            let subscriberSessionDescription: String

            if
                isFastReconnecting,
                let subscriber = await coordinator.stateAdapter.subscriber {
                let offer = try await subscriber.createOffer()
                subscriberSessionDescription = offer.sdp
            } else {
                try await publisher?.ensureSetUpHasBeenCompleted()
                subscriberSessionDescription = try await RTCTemporaryPeerConnection(
                    sessionID: coordinator.stateAdapter.sessionID,
                    peerConnectionFactory: coordinator.stateAdapter.peerConnectionFactory,
                    configuration: coordinator.stateAdapter.connectOptions.rtcConfiguration,
                    sfuAdapter: sfuAdapter,
                    videoOptions: coordinator.stateAdapter.videoOptions,
                    localAudioTrack: publisher?.localTrack(of: .audio) as? RTCAudioTrack,
                    localVideoTrack: publisher?.localTrack(of: .video) as? RTCVideoTrack
                ).createOffer().sdp
            }
            return subscriberSessionDescription
        }

        /// Performs the join process.
        /// - Parameters:
        ///   - coordinator: The WebRTC coordinator.
        ///   - sfuAdapter: The SFU adapter.
        private func join(
            coordinator: WebRTCCoordinator,
            sfuAdapter: SFUAdapter
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

            let joinResponse = try await sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
                .nextValue(timeout: WebRTCConfiguration.timeout.join)

            try Task.checkCancellation()

            let participants = joinResponse
                .callState
                .participants
                .map { $0.toCallParticipant() }
                .reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }

            await coordinator
                .stateAdapter
                .enqueue { _ in participants }

            try Task.checkCancellation()

            try await coordinator
                .stateAdapter
                .publisher?
                .didUpdateCallSettings(await coordinator.stateAdapter.callSettings)

            sfuAdapter.sendHealthCheck()

            context.fastReconnectDeadlineSeconds = TimeInterval(
                joinResponse.fastReconnectDeadlineSeconds
            )

            try Task.checkCancellation()

            try await context.authenticator.waitForConnect(on: sfuAdapter)

            try Task.checkCancellation()

            try await coordinator.stateAdapter.restoreScreenSharing()
        }
    }
}
