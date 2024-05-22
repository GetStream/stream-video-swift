//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine {
    /// A class representing a stage in the `StreamCallStateMachine`.
    class Stage: StreamStateMachineStage {

        /// Enumeration of possible stage identifiers.
        enum ID: Hashable, CaseIterable {
            case idle
            case joining
            case joined
            case accepting
            case accepted
            case rejecting
            case rejected
            case error
        }

        /// The identifier for the current stage.
        let id: ID

        /// A weak reference to the associated `Call` object.
        weak var call: Call?

        /// The transition closure for the stage.
        var transition: Transition?

        /// Initializes a new stage with the given identifier and call.
        ///
        /// - Parameters:
        ///   - id: The identifier for the stage.
        ///   - call: The associated `Call` object.
        init(id: ID, call: Call?) {
            self.id = id
            self.call = call
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            nil // No-op
        }
    }
}
