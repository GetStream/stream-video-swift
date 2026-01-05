//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates an accepted stage for a call with the given response.
    ///
    /// - Parameters:
    ///   - context: The call context containing necessary state
    ///   - response: The response received from accepting the call
    /// - Returns: A new `AcceptedStage` instance
    static func accepted(
        _ context: Context,
        response: AcceptCallResponse
    ) -> Call.StateMachine.Stage {
        AcceptedStage(
            .init(
                call: context.call,
                output: .accepted(response)
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// Represents the accepted stage in the call state machine.
    final class AcceptedStage: Call.StateMachine.Stage, @unchecked Sendable {
        /// Creates a new accepted stage with the provided context.
        ///
        /// - Parameter context: The call context containing necessary state
        init(
            _ context: Context
        ) {
            super.init(id: .accepted, context: context)
        }

        /// Handles state transitions to the accepted stage.
        ///
        /// Valid transitions:
        /// - From: AcceptingStage
        /// - To: AcceptedStage
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .accepting:
                return self
            default:
                return nil
            }
        }
    }
}
