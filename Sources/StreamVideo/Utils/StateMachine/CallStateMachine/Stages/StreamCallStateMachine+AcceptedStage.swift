//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    /// Creates an accepted stage for the provided call with the specified response.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - response: The `AcceptCallResponse` received.
    /// - Returns: An `AcceptedStage` instance.
    static func accepted(
        _ call: Call?,
        response: AcceptCallResponse
    ) -> StreamCallStateMachine.Stage {
        AcceptedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the accepted stage in the `StreamCallStateMachine`.
    final class AcceptedStage: StreamCallStateMachine.Stage {
        let response: AcceptCallResponse

        /// Initializes a new accepted stage with the provided call and response.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - response: The `AcceptCallResponse` received.
        init(
            _ call: Call?,
            response: AcceptCallResponse
        ) {
            self.response = response
            super.init(id: .accepted, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `AcceptedStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `AcceptingStage`
        ///   - To: `AcceptedStage`
        override func transition(
            from previousStage: StreamCallStateMachine.Stage
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
