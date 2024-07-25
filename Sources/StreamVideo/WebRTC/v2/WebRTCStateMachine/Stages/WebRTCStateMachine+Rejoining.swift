//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func rejoining(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        disconnectionSource: WebSocketConnectionState.DisconnectionSource,
        reconnectionStrategy: ReconnectionStrategy
    ) -> WebRTCStateMachine.Stage {
        RejoiningStage(
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

    final class RejoiningStage: WebRTCStateMachine.Stage {

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
            super.init(id: .rejoining, coordinator: coordinator)
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
                    let response = try await coordinator.authenticationAdapter.authenticate(updateSession: true)

                    let videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    let connectOptions = ConnectOptions(
                        iceServers: response.credentials.iceServers
                    )
                    let callSettings = response.call.settings.toCallSettings

                    coordinator.peerConnectionsAdapter.closeConnections(
                        of: [
                            .publisher,
                            .subscriber
                        ]
                    )

                    try transition?(
                        .connecting(
                            coordinator,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions
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
                                reconnectionStrategy: reconnectionStrategy
                            )
                        )
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }
}
