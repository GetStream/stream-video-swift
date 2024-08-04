//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func leaving(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        LeavingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class LeavingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .leaving, context: context)
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
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }
                    coordinator._notifyLeave(
                        context.webSocketClient,
                        reason: ""
                    )

                    context.webSocketClient.disconnect {}
                    // TODO: further cleanup

                    try transition?(.idle(context))
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
