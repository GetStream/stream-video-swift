//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine {
    class Stage: StateMachineStage {

        enum ID: Hashable {
            case idle
            case joining
            case joined
            case accepting
            case accepted
            case rejecting
            case rejected
            case error
        }

        let id: ID
        weak var call: Call?

        var transition: Transition?

        init(id: ID, call: Call?) {
            self.id = id
            self.call = call
        }

        func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            nil // No-op
        }
    }
}
