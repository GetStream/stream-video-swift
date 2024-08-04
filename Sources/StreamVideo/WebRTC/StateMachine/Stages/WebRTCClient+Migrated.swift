//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func migrated(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        MigratedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class MigratedStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .migrated, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .migrating:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let client = context.client,
                        let migratingSFUAdapter = client.migratingSFUAdapter
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    let response = try await client
                        .callAuthenticator
                        .authenticate(
                            create: false,
                            migratingFrom: client.sfuAdapter.hostname
                        )

                    client.prepare(
                        .migration(
                            url: response.credentials.server.url,
                            token: response.credentials.token,
                            webSocketURL: response.credentials.server.wsEndpoint,
                            fromSfuName: client.sfuAdapter.hostname,
                            ownCapabilities: response.ownCapabilities,
                            audioSettings: response.call.settings.audio
                        )
                    )

                    context.videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    context.connectOptions = ConnectOptions(iceServers: response.credentials.iceServers)

                    client.migratingSFUAdapter?.connect()
                    client.publisher?.update(
                        configuration: context.connectOptions?.rtcConfiguration
                    )

                    _ = try await migratingSFUAdapter
                        .$connectionState
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
                        .joining(
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
