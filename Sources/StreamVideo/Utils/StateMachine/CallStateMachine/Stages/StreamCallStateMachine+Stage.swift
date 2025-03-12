//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine {
    /// A class representing a stage in the `StreamCallStateMachine`.
    class Stage: StreamStateMachineStage, @unchecked Sendable {

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

        let container: String = "Call"

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

        func willTransitionAway() { /* No-op */ }
        func didTransitionAway() { /* No-op */ }

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
