//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine.Stage {

    static func idle(_ coordinator: WebRTCCoordinator?) -> WebRTCStateMachine.Stage {
        IdleStage(coordinator)
    }
}

extension WebRTCStateMachine.Stage {

    final class IdleStage: WebRTCStateMachine.Stage {

        convenience init(_ coordinator: WebRTCCoordinator?) {
            self.init(id: .idle, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
