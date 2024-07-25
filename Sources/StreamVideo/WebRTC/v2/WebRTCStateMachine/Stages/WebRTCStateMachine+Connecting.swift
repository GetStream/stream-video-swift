//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine.Stage {

    static func connecting(
        _ coordinator: WebRTCCoordinator?,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) -> WebRTCStateMachine.Stage {
        ConnectingStage(
            coordinator,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class ConnectingStage: WebRTCStateMachine.Stage {

        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions

        init(
            _ coordinator: WebRTCCoordinator?,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        ) {
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            super.init(id: .connecting, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute()
                return self
            case .rejoining:
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

                let sfuAdapter = SFUAdapter(
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

                coordinator.peerConnectionsAdapter.callSettings = callSettings
                coordinator.peerConnectionsAdapter.videoOptions = videoOptions
                coordinator.peerConnectionsAdapter.connectOptions = connectOptions
                coordinator.peerConnectionsAdapter.sfuAdapter = sfuAdapter

                // Setup user-media
                coordinator.localTracksAdapter.setupIfRequired(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions,
                    videoConfig: coordinator.videoConfig
                )

                sfuAdapter.connect()

                do {
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
                        .nextValue(timeout: 10)

                    try transition?(
                        .connected(
                            coordinator,
                            sfuAdapter: sfuAdapter,
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
