//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    /// Creates an error stage for the provided call with the specified error.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - error: The error associated with the stage.
    /// - Returns: An `ErrorStage` instance.
    static func error(
        _ call: Call?,
        error: Error
    ) -> StreamCallStateMachine.Stage {
        ErrorStage(
            call,
            error: error
        )
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the error stage in the `StreamCallStateMachine`.
    final class ErrorStage: StreamCallStateMachine.Stage {
        let error: Error

        /// Initializes a new error stage with the provided call and error.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - error: The error associated with the stage.
        init(
            _ call: Call?,
            error: Error
        ) {
            self.error = error
            super.init(id: .error, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `ErrorStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transitions:
        ///   - From: `JoiningStage`, `AcceptingStage`, `RejectingStage`
        ///   - To: `IdleStage`
        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining, .accepting, .rejecting:
                Task { [error] in
                    do {
                        try transition?(.idle(call))
                        log.error(error)
                    } catch {
                        log.error(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
