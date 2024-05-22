//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    /// Creates an idle stage for the provided call.
    ///
    /// - Parameter call: The associated `Call` object.
    /// - Returns: An `IdleStage` instance.
    static func idle(_ call: Call?) -> StreamCallStateMachine.Stage {
        IdleStage(call)
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the idle stage in the `StreamCallStateMachine`.
    final class IdleStage: StreamCallStateMachine.Stage {

        /// Initializes a new idle stage with the provided call.
        ///
        /// - Parameter call: The associated `Call` object.
        convenience init(_ call: Call?) {
            self.init(id: .idle, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        /// - Note: IdleStage is a valid transition from any other stage.
        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
