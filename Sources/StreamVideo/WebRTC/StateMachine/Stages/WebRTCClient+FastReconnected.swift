//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func fastReconnected(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        FastReconnectedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class FastReconnectedStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .fastReconnected, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .fastReconnecting:
                Task {
                    do {
                        try transition?(
                            .joining(
                                context
                            )
                        )
                    } catch {
                        log.error(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
