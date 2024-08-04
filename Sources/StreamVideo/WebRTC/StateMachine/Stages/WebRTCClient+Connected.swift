//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func connected(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        ConnectedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class ConnectedStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .connected, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
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
