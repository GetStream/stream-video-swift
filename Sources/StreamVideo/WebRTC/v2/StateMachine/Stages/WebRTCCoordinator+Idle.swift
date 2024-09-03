//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func idle(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        IdleStage(context)
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class IdleStage: WebRTCCoordinator.StateMachine.Stage {

        convenience init(_ context: Context) {
            self.init(id: .idle, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
