//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

extension StreamCallStateMachine.Stage {

    /// Creates a rejected stage for the provided call with the specified response.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - response: The response for the rejected call.
    /// - Returns: A `RejectedStage` instance.
    static func rejected(
        _ call: Call?,
        response: RejectCallResponse
    ) -> StreamCallStateMachine.Stage {
        RejectedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the rejected stage in the `StreamCallStateMachine`.
    final class RejectedStage: StreamCallStateMachine.Stage, @unchecked Sendable {
        let response: RejectCallResponse

        /// Initializes a new rejected stage with the provided call and response.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - response: The response for the rejected call.
        init(
            _ call: Call?,
            response: RejectCallResponse
        ) {
            self.response = response
            super.init(id: .rejected, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `RejectedStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `RejectingStage`
        override func transition(
            from previousStage: StreamCallStateMachine.Stage
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
