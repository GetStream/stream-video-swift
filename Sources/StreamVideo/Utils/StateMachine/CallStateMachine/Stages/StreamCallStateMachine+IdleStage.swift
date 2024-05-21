//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func idle(_ call: Call?) -> StreamCallStateMachine.Stage {
        IdleStage(call)
    }
}

extension StreamCallStateMachine.Stage {

    final class IdleStage: StreamCallStateMachine.Stage {
        convenience init(_ call: Call?) {
            self.init(id: .idle, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
