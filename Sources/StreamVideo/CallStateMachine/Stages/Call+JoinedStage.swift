//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates a joined stage for the provided call with the specified response.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - response: The `JoinCallResponse` object.
    /// - Returns: A `JoinedStage` instance.
    static func joined(
        _ context: Context,
        response: JoinCallResponse
    ) -> Call.StateMachine.Stage {
        JoinedStage(
            .init(
                call: context.call,
                output: .joined(response)
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// A class representing the joined stage in the `StreamCallStateMachine`.
    final class JoinedStage: Call.StateMachine.Stage, @unchecked Sendable {

        /// Initializes a new joined stage with the provided call and response.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - response: The `JoinCallResponse` object.
        init(
            _ context: Context
        ) {
            super.init(id: .joined, context: context)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `JoinedStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `JoiningStage`
        ///   - To: `JoinedStage`
        override func transition(
            from previousStage: Call.StateMachine.Stage
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
