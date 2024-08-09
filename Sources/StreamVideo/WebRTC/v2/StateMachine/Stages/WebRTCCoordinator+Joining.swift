//
//  WebRTCCoordinator+Joining.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
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

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(coordinator: coordinator)
                            .buildRequest(
                                with: isFastReconnecting ? .fastReconnect : .default,
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

                    if isFastReconnecting {
                        context.reconnectAttempts += 1
                    }

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
                    do {
                        var context = self.context
                        context.disconnectionSource = .serverInitiated(
                            error: .init(error.localizedDescription)
                        )
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
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

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(coordinator: coordinator)
                            .buildRequest(
                                with: .migration(fromHostname: context.migratingFromSFU),
                                subscriberSdp: try await buildSubscriberSessionDescription(
                                    coordinator: coordinator,
                                    sfuAdapter: sfuAdapter,
                                    isFastReconnecting: false,
                                    publisher: context.previousSessionPublisher
                                ),
                                reconnectAttempt: context.reconnectAttempts,
                                publisher: context.previousSessionPublisher
                            )
                    )

                    context.reconnectAttempts += 1

                    try await join(
                        coordinator: coordinator,
                        sfuAdapter: sfuAdapter
                    )

                    context.migratingFromSFU = ""

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    do {
                        if let clientError = error as? ClientError {
                            log.error(clientError)
                        }
                        context.disconnectionSource = .serverInitiated(
                            error: .init(error.localizedDescription)
                        )
                        context.reconnectionStrategy = .rejoin
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
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

                    await sfuAdapter.sendJoinRequest(
                        WebRTCJoinRequestFactory(coordinator: coordinator)
                            .buildRequest(
                                with: .rejoin(fromSessionID: isRejoiningFromSessionID),
                                subscriberSdp: try await buildSubscriberSessionDescription(
                                    coordinator: coordinator,
                                    sfuAdapter: sfuAdapter,
                                    isFastReconnecting: false,
                                    publisher: context.previousSessionPublisher
                                ),
                                reconnectAttempt: context.reconnectAttempts,
                                publisher: context.previousSessionPublisher
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
                    do {
                        context.disconnectionSource = .serverInitiated(
                            error: .init(error.localizedDescription)
                        )
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
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
                let subscriber = await coordinator.stateAdapter.subscriber
            {
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

            await context.previousSFUAdapter?.disconnect()
            let joinResponse = try await sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
                .nextValue(timeout: 10)
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
        }
    }
}

