//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func cleanReconnecting(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        CleanReconnectingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class CleanReconnectingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .cleanReconnecting, context: context)
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
                
                coordinator._closeConnections(
                    of: [
                        .publisher,
                        .subscriber
                    ]
                )


                do {
                    context.webSocketClient = try coordinator._createSFUWebSocket()
                    context.webSocketClient.connect()

                    _ = try await context
                        .webSocketClient
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
                        .cleanReconnected(
                            context
                        )
                    )
                } catch {
                    do {
                        context.reconnectionStrategy = context.nextReconnectionStrategy()
                        context.disconnectionSource = .serverInitiated(error: ClientError(error.localizedDescription))

                        try transition?(
                            .disconnected(context)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }
    }
}
