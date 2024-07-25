//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func joining(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) -> WebRTCStateMachine.Stage {
        JoiningStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class JoiningStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        ) {
            self.sfuAdapter = sfuAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            super.init(id: .joining, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connected:
                execute(isFastReconnecting: false)
                return self
            case .fastReconnected:
                execute(isFastReconnecting: true)
                return self
            case .cleanReconnected:
                execute(isFastReconnecting: false)
                return self
            case .migrated:
                if let fromSFUAdapter = (previousStage as? MigratedStage)?.fromSFUAdapter {
                    execute(isFastReconnecting: false, fromSFUAdapter: fromSFUAdapter)
                } else {
                    Task {
                        transitionErrorOrLog(ClientError("Invalid SFU migration details."))
                    }
                }
                return self
            default:
                return nil
            }
        }

        private func execute(
            isFastReconnecting: Bool,
            fromSFUAdapter: SFUAdapter? = nil
        ) {
            Task {
                guard let coordinator else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                do {
                    let subscriberSessionDescription = try await buildSubscriberSessionDescription(
                        coordinator,
                        isFastReconnecting: isFastReconnecting
                    )

                    if let fromSFUAdapter {
                        sfuAdapter.migrate(
                            sessionId: coordinator.authenticationAdapter.sessionId,
                            subscriberSessionDescription: subscriberSessionDescription,
                            token: coordinator.authenticationAdapter.token,
                            migratingFrom: fromSFUAdapter.hostname
                        )
                    } else {
                        sfuAdapter.join(
                            sessionId: coordinator.authenticationAdapter.sessionId,
                            subscriberSessionDescription: subscriberSessionDescription,
                            isFastReconnecting: isFastReconnecting,
                            token: coordinator.authenticationAdapter.token
                        )
                    }

                    let joinResponse = try await sfuAdapter
                        .eventSubject
                        .compactMap {
                            if case let .joinResponse(response) = $0 {
                                return response
                            } else {
                                return nil
                            }
                        }
                        .nextValue(timeout: 15)

                    fromSFUAdapter?.disconnect()

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
                        try transition?(
                            .disconnected(
                                coordinator,
                                sfuAdapter: sfuAdapter,
                                callSettings: callSettings,
                                videoOptions: videoOptions,
                                connectOptions: connectOptions,
                                disconnectionSource: .serverInitiated(error: ClientError(error.localizedDescription)),
                                reconnectionStrategy: reconnectionStrategyToUse()
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
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
