//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func rejoining(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        RejoiningStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class RejoiningStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .rejoining, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
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
                guard let coordinator = context.client else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                do {
                    let response = try await context.callAuthenticator.authenticate()

                    context.videoOptions = VideoOptions(
                        targetResolution: response.call.settings.video.targetResolution
                    )
                    context.connectOptions = ConnectOptions(
                        iceServers: response.credentials.iceServers
                    )
                    context.callSettings = response.call.settings.toCallSettings

                    coordinator._closeConnections(
                        of: [
                            .publisher,
                            .subscriber
                        ]
                    )

                    try transition?(
                        .connecting(
                            context
                        )
                    )
                } catch {
                    do {
                        context.disconnectionSource = .serverInitiated(error: ClientError(error.localizedDescription))
                        try transition?(
                            .disconnected(
                                context
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
