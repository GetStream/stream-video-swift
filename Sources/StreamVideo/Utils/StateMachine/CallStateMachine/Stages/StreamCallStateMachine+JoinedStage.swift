//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    /// Creates a joined stage for the provided call with the specified response.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - response: The `JoinCallResponse` object.
    /// - Returns: A `JoinedStage` instance.
    static func joined(
        _ call: Call?,
        response: JoinCallResponse
    ) -> StreamCallStateMachine.Stage {
        JoinedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the joined stage in the `StreamCallStateMachine`.
    final class JoinedStage: StreamCallStateMachine.Stage {
        let response: JoinCallResponse

        /// Initializes a new joined stage with the provided call and response.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - response: The `JoinCallResponse` object.
        init(
            _ call: Call?,
            response: JoinCallResponse
        ) {
            self.response = response
            super.init(id: .joined, call: call)
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
            from previousStage: StreamCallStateMachine.Stage
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
