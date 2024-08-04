//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func joining(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        JoiningStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class JoiningStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .joining, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connected:
                execute(isFastReconnecting: false)
                return self
//            case .fastReconnected:
//                execute(isFastReconnecting: true)
//                return self
//            case .cleanReconnected:
//                execute(isFastReconnecting: false)
//                return self
//            case .migrated:
//                if let fromSFUAdapter = (previousStage as? MigratedStage)?.fromSFUAdapter {
//                    execute(isFastReconnecting: false, fromSFUAdapter: fromSFUAdapter)
//                } else {
//                    Task {
//                        transitionErrorOrLog(ClientError("Invalid SFU migration details."))
//                    }
//                }
//                return self
            default:
                return nil
            }
        }

        private func execute(
            isFastReconnecting: Bool
        ) {
            Task {
                guard 
                    let coordinator = context.client
                else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                do {
//                    let subscriberSessionDescription = try await buildSubscriberSessionDescription(
//                        coordinator,
//                        isFastReconnecting: isFastReconnecting
//                    )

                    if context.fromWebSocketClient != nil {
//                        sfuAdapter.migrate(
//                            sessionId: coordinator.authenticationAdapter.sessionId,
//                            subscriberSessionDescription: subscriberSessionDescription,
//                            token: coordinator.authenticationAdapter.token,
//                            migratingFrom: fromSFUAdapter.hostname
//                        )
                        let subscriberSessionDescription = try await coordinator.tempOfferSdp()
                        await join(
                            coordinator,
                            subscriberSessionDescription: subscriberSessionDescription,
                            isFastReconnecting: false,
                            isMigrating: true,
                            webSocketClient: context.webSocketClient
                        )
                    } else {
                        let subscriberSessionDescription: String
                        if isFastReconnecting, let subscriber = coordinator.subscriber {
                            let offer = try await subscriber.createOffer()
                            subscriberSessionDescription = offer.sdp
                        } else {
                            subscriberSessionDescription = try await coordinator.tempOfferSdp()
                        }
//                        sfuAdapter.join(
//                            sessionId: coordinator.authenticationAdapter.sessionId,
//                            subscriberSessionDescription: subscriberSessionDescription,
//                            isFastReconnecting: isFastReconnecting,
//                            token: coordinator.authenticationAdapter.token
//                        )

                        await join(
                            coordinator,
                            subscriberSessionDescription: subscriberSessionDescription,
                            isFastReconnecting: isFastReconnecting,
                            isMigrating: false,
                            webSocketClient: context.webSocketClient
                        )
                    }

                    let joinResponse = try await context
                        .webSocketClient
                        .eventSubject
                        .compactMap {
                            if case let .sfuEvent(sfuEvent) = $0 {
                                return sfuEvent
                            } else {
                                return nil
                            }
                        }
                        .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                            if case let .joinResponse(response) = event {
                                return response
                            } else {
                                return nil
                            }
                        }
                        .nextValue(timeout: 15)
//
                    context.fromWebSocketClient?.disconnect {}
                    context.fromWebSocketClient = nil

                    try transition?(
                        .joined(
                            coordinator,
                            sfuAdapter: sfuAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            fastReconnectDeadlineSeconds: TimeInterval(joinResponse.fastReconnectDeadlineSeconds)
                        )
                    )
                } catch {
                    do {
//                        try transition?(
//                            .disconnected(
//                                coordinator,
//                                sfuAdapter: sfuAdapter,
//                                callSettings: callSettings,
//                                videoOptions: videoOptions,
//                                connectOptions: connectOptions,
//                                disconnectionSource: .serverInitiated(error: ClientError(error.localizedDescription)),
//                                reconnectionStrategy: reconnectionStrategyToUse()
//                            )
//                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }

        private func join(
            _ coordinator: WebRTCClient,
            subscriberSessionDescription: String,
            isFastReconnecting: Bool,
            isMigrating: Bool,
            webSocketClient: WebSocketClient
        ) async {
            let payload = await coordinator.makeJoinRequest(
                subscriberSdp: subscriberSessionDescription,
                migrating: isMigrating,
                fastReconnect: isFastReconnecting
            )
            var event = Stream_Video_Sfu_Event_SfuRequest()
            event.requestPayload = .joinRequest(payload)

            webSocketClient.engine?.send(message: event)
        }

        private func buildSubscriberSessionDescription(
            _ coordinator: WebRTCCoordinator,
            isFastReconnecting: Bool
        ) async throws -> String {
            if isFastReconnecting {
                return "" // TODO: provider subscriber SessionDescription
            } else {
                return try await temporarySubscriberSessionDescription(coordinator)
            }
        }

        private func temporarySubscriberSessionDescription(
            _ coordinator: WebRTCCoordinator
        ) async throws -> String {
            try await coordinator.peerConnectionsAdapter.makeTemporaryOffer(
                connectOptions: connectOptions
            ).sdp
        }

        private func reconnectionStrategyToUse() -> ReconnectionStrategy {
            switch sfuAdapter.preferredReconnectionStrategy {
            case .fast:
                return .fast(
                    disconnectedSince: Date(),
                    deadline: 0 // Skip
                )

            case .clean:
                return .clean(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )

            case .rejoin:
                return .rejoin(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )

            case .migrate:
                return .migrate

            default:
                return .clean(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )
            }
        }
    }
}
