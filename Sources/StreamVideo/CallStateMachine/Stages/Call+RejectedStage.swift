//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

extension Call.StateMachine.Stage {

    /// Creates a rejected stage for a call with the given response.
    ///
    /// - Parameters:
    ///   - context: The call context containing necessary state
    ///   - response: The response received from rejecting the call
    /// - Returns: A new `RejectedStage` instance
    static func rejected(
        _ context: Context,
        response: RejectCallResponse
    ) -> Call.StateMachine.Stage {
        RejectedStage(
            .init(
                call: context.call,
                output: .rejected(response)
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// Represents the rejected stage in the call state machine.
    final class RejectedStage: Call.StateMachine.Stage, @unchecked Sendable {
        /// Creates a new rejected stage with the provided context.
        ///
        /// - Parameter context: The call context containing necessary state
        init(
            _ context: Context
        ) {
            super.init(id: .rejected, context: context)
        }

        /// Handles state transitions to the rejected stage.
        ///
        /// Valid transitions:
        /// - From: RejectingStage
        /// - To: RejectedStage
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .rejecting:
                return self
            default:
                return nil
            }
        }
    }
}
