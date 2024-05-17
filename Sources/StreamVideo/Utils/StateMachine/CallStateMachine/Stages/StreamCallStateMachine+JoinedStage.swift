//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func joined(
        _ call: Call,
        response: JoinCallResponse
    ) -> StreamCallStateMachine.Stage {
        JoinedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    final class JoinedStage: StreamCallStateMachine.Stage {
        let response: JoinCallResponse

        init(
            _ call: Call,
            response: JoinCallResponse
        ) {
            self.response = response
            super.init(id: .joined, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                return self
            default:
                return nil
            }
        }
    }
}
