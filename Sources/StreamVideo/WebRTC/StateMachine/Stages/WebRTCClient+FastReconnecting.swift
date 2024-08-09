//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func fastReconnecting(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        FastReconnectingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class FastReconnectingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .fastReconnecting, context: context)
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
            Task { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let client = context.client,
                        let sfuAdapter = client.sfuAdapter
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    log.debug("Refreshing webSocket", subsystems: .webRTC)
                    sfuAdapter.refresh(
                        webSocketConfiguration: .init(
                            url: sfuAdapter.connectURL,
                            eventNotificationCenter: client.eventNotificationCenter
                        )
                    )

                    log.debug("Connecting webSocket", subsystems: .webRTC)
                    sfuAdapter.connect()

                    log.debug("Waiting for webSocket state to change to authenticating", subsystems: .webRTC)
                    _ = try await sfuAdapter
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
                        .fastReconnected(
                            context
                        )
                    )
                } catch(let blockError) {
                    do {
                        context.reconnectionStrategy = context.nextReconnectionStrategy()
                        context.disconnectionSource = .serverInitiated(error: ClientError(blockError.localizedDescription))

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
