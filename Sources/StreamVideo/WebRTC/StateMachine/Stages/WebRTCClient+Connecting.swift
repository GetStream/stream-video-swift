//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func connecting(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        ConnectingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class ConnectingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .connecting, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute(create: true, updateSession: false)
                return self
            case .rejoining:
                execute(create: false, updateSession: true)
                return self
            default:
                return nil
            }
        }

        private func execute(create: Bool, updateSession: Bool) {
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let client = context.client
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }
                    if updateSession {
                        client.updateSession()
                    }

                    if !updateSession {
                        client._closeConnections(of: [.publisher, .subscriber])
                    }

                    let response = try await client
                        .callAuthenticator
                        .authenticate(create: create, migratingFrom: nil)

                    client.prepare(
                        .connect(
                            url: response.credentials.server.url,
                            token: response.credentials.token,
                            webSocketURL: response.credentials.server.wsEndpoint,
                            ownCapabilities: response.ownCapabilities,
                            audioSettings: response.call.settings.audio,
                            connectOptions: ConnectOptions(iceServers: response.credentials.iceServers)
                        )
                    )

                    let callSettings = context.callSettings ?? response.call.settings.toCallSettings
                    context.callSettings = callSettings
                    client.callSettings = callSettings
                    context.videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    context.connectOptions = ConnectOptions(
                        iceServers: response.credentials.iceServers
                    )

                    try await client.setupUserMedia(callSettings: callSettings)
                    client.sfuAdapter.connect()

                    _ = try await client
                        .sfuAdapter
                        .$connectionState
                        .filter {
                            switch $0 {
                            case .authenticating:
                                return true
                            default:
                                return false
                            }
                        }
                        .nextValue(timeout: 5)

                    try transition?(
                        .connected(
                            context
                        )
                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
