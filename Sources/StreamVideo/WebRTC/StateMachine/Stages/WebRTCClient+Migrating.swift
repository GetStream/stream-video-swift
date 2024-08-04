//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension WebRTCClient.StateMachine.Stage {

    static func migrating(
        _ context: Context
    ) -> WebRTCStateMachine.Stage {
        MigratingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class MigratingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .migrating, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
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
                    guard let coordinator = context.client else {
                        transitionErrorOrLog(
                            ClientError(
                                "WebRCTAdapter instance not available."
                            )
                        )
                        return
                    }

                    let response = try await context.callAuthenticator.authenticate()

                    context.videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    context.connectOptions = ConnectOptions(
                        iceServers: response.credentials.iceServers
                    )

                    let fromSFU = context.webSocketClient
                    context.webSocketClient = coordinator._createSFUWebSocket(
                        URL(string: response.credentials.server.wsEndpoint)!,
                        apiKey: context.apiKey
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
