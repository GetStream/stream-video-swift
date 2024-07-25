//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension WebRTCStateMachine.Stage {

    static func migrating(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) -> WebRTCStateMachine.Stage {
        MigratingStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class MigratingStage: WebRTCStateMachine.Stage {

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
            super.init(id: .migrating, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                do {
                    guard let coordinator else {
                        transitionErrorOrLog(
                            ClientError(
                                "WebRCTAdapter instance not available."
                            )
                        )
                        return
                    }

                    let response = try await coordinator.authenticationAdapter.authenticate(updateSession: false)

                    let videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    let connectOptions = ConnectOptions(
                        iceServers: response.credentials.iceServers
                    )

                    let toSFUAdapter = SFUAdapter(
                        sessionId: coordinator.authenticationAdapter.sessionId,
                        url: coordinator.authenticationAdapter.url,
                        service: .init(
                            apiKey: coordinator.authenticationAdapter.apiKey,
                            hostname: coordinator.authenticationAdapter.hostname,
                            token: coordinator.authenticationAdapter.token,
                            httpClient: coordinator.environment.httpClientBuilder()
                        ),
                        eventNotificationCenter: coordinator.eventNotificationCenter,
                        environment: coordinator.environment
                    )

                    // TODO: We should not close the subscriber until the new
                    // one has been established
//                    coordinator.peerConnectionsAdapter.closeConnections(
//                        of: [
//                            .subscriber
//                        ]
//                    )

                    coordinator.peerConnectionsAdapter.callSettings = callSettings
                    coordinator.peerConnectionsAdapter.videoOptions = videoOptions
                    coordinator.peerConnectionsAdapter.connectOptions = connectOptions
                    coordinator.peerConnectionsAdapter.sfuAdapter = toSFUAdapter

                    try transition?(
                        .migrated(
                            coordinator,
                            fromSFUAdapter: sfuAdapter,
                            toSFUAdapter: toSFUAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions
                        )
                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
