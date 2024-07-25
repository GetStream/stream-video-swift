//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func fastReconnecting(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        disconnectionSource: WebSocketConnectionState.DisconnectionSource,
        reconnectionStrategy: ReconnectionStrategy
    ) -> WebRTCStateMachine.Stage {
        FastReconnectingStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions,
            disconnectionSource: disconnectionSource,
            reconnectionStrategy: reconnectionStrategy
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class FastReconnectingStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions
        private let disconnectionSource: WebSocketConnectionState.DisconnectionSource
        private let reconnectionStrategy: ReconnectionStrategy

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions,
            disconnectionSource: WebSocketConnectionState.DisconnectionSource,
            reconnectionStrategy: ReconnectionStrategy
        ) {
            self.sfuAdapter = sfuAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            self.disconnectionSource = disconnectionSource
            self.reconnectionStrategy = reconnectionStrategy
            super.init(id: .fastReconnecting, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .disconnected:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
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
                    sfuAdapter.connect()

                    _ = try await sfuAdapter
                        .connectionSubject
                        .filter {
                            switch $0 {
                            case .authenticating:
                                return true
                            default:
                                return false
                            }
                        }
                        .nextValue(timeout: 15)

                    try transition?(
                        .fastReconnected(
                            coordinator,
                            sfuAdapter: sfuAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            disconnectionSource: disconnectionSource,
                            reconnectionStrategy: reconnectionStrategy
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
                                reconnectionStrategy: { [reconnectionStrategy, callSettings, videoOptions, connectOptions] in
                                    switch reconnectionStrategy {
                                    case .fast:
                                        return .clean(
                                            callSettings: callSettings,
                                            videoOptions: videoOptions,
                                            connectOptions: connectOptions
                                        )
                                    case let .clean(callSettings, videoOptions, connectOptions):
                                        return .rejoin(
                                            callSettings: callSettings,
                                            videoOptions: videoOptions,
                                            connectOptions: connectOptions
                                        )
                                    default:
                                        return reconnectionStrategy
                                    }
                                }()
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }
    }
}
