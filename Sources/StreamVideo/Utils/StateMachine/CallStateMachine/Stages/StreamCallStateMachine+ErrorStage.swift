//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func error(
        _ call: Call?,
        error: Error
    ) -> StreamCallStateMachine.Stage {
        ErrorStage(
            call,
            error: error
        )
    }
}

extension StreamCallStateMachine.Stage {

    final class ErrorStage: StreamCallStateMachine.Stage {
        let error: Error

        init(
            _ call: Call?,
            error: Error
        ) {
            self.error = error
            super.init(id: .error, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                Task {
                    transition?(.idle(call))
                }
                return self
            default:
                return nil
            }
        }
    }
}
