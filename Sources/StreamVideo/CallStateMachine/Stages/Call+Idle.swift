//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates an idle stage for the call state machine.
    ///
    /// - Parameter context: The context containing necessary state
    /// - Returns: A new `IdleStage` instance
    static func idle(_ context: Context) -> Call.StateMachine.Stage {
        IdleStage(context)
    }
}

extension Call.StateMachine.Stage {

    /// Represents the idle stage in the call state machine.
    final class IdleStage: Call.StateMachine.Stage, @unchecked Sendable {

        /// Creates a new idle stage with the provided context.
        ///
        /// - Parameter context: The context containing necessary state
        convenience init(_ context: Context) {
            self.init(id: .idle, context: context)
        }

        /// Handles state transitions to the idle stage.
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        /// - Note: IdleStage is a valid transition from any other stage
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
