//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension WebRTCCoordinator.StateMachine.Stage {

    static func joining(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        JoiningStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class JoiningStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .joining, context: context)
        }

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

                    if !isFastReconnecting {
                        try await coordinator.stateAdapter.configurePeerConnections()
                    }

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

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    if isFastReconnecting {
                        await coordinator.stateAdapter.publisher?.restartICE()
                        await coordinator.stateAdapter.subscriber?.restartICE()
                    }

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    context.reconnectionStrategy = context
                        .reconnectionStrategy
                        .next
                    transitionDisconnectOrError(error)
                }
            }
        }

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

                    try await coordinator.stateAdapter.configurePeerConnections()

                    /// Send a joinRequest to the WS connection. The request will include:
                    /// - The hostname of the SFU we are migrating from
                    /// - A new Subscriber SDP that is built using the **newly created** publisher. (Check with Marcelo)
                    /// - The announced tracks of the **newly created**  publisher
                    /// - The reconnect attempts
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

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    if let clientError = error as? ClientError {
                        log.error(clientError)
                    }
                    context.reconnectionStrategy = .rejoin
                    transitionDisconnectOrError(error)
                }
            }
        }

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
                            "WebRCTAdapter instance not available."
                        )
                    }

                    try await coordinator.stateAdapter.configurePeerConnections()

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

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    transitionDisconnectOrError(error)
                }
            }
        }

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

            let joinResponse = try await sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
                .nextValue(timeout: 10)

            /// We start publishing as soon as we get the joinResponse to ensure better UI/UX.
            try await coordinator
                .stateAdapter
                .publisher?
                .didUpdateCallSettings(await coordinator.stateAdapter.callSettings)

            /// Send the first healthCheck to the newly connected SFU.
            sfuAdapter.sendHealthCheck()

            context.fastReconnectDeadlineSeconds = TimeInterval(
                joinResponse.fastReconnectDeadlineSeconds
            )

            _ = try await sfuAdapter
                .$connectionState
                .filter {
                    switch $0 {
                    case .connected:
                        return true
                    default:
                        return false
                    }
                }
                .nextValue(timeout: 10)

            let participants = joinResponse
                .callState
                .participants
                .map { $0.toCallParticipant() }
                .reduce(into: [String: CallParticipant]()) { partialResult, participant in
                    partialResult[participant.sessionId] = participant
                }

            await coordinator
                .stateAdapter
                .didUpdateParticipants(participants)

            try await coordinator.stateAdapter.restoreScreenSharing()
        }
    }
}
