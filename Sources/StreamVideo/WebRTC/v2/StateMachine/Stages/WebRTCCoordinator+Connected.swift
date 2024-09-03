//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func connected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class ConnectedStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .connected, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
                Task { transitionOrError(.joining(context)) }
                return self
            default:
                return nil
            }
        }
    }
}
