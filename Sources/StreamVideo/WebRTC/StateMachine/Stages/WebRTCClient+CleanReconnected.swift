//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func cleanReconnected(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        CleanReconnectedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class CleanReconnectedStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .cleanReconnected, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .cleanReconnecting:
                Task {
                    do {
                        try transition?(
                            .joining(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
