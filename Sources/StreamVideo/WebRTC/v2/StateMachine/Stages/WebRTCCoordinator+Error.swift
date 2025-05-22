//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates an error stage for the provided call with the specified error.
    ///
    /// - Parameters:
    ///   - context: The associated `Context` object.
    ///   - error: The error associated with the stage.
    /// - Returns: An `ErrorStage` instance.
    static func error(
        _ context: Context,
        error: Error
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ErrorStage(
            context,
            error: error
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// A class representing the error stage in the `StreamCallStateMachine`.
    final class ErrorStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        let error: Error

        /// Initializes a new error stage with the provided call and error.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - error: The error associated with the stage.
        init(
            _ context: Context,
            error: Error
        ) {
            self.error = error
            super.init(id: .error, context: context)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `ErrorStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            Task { [error] in
                do {
                    log.error(error, subsystems: .webRTC)
                    try transition?(.cleanUp(context))
                } catch let transitionError {
                    log.error(transitionError, subsystems: .webRTC)
                }
            }
            return self
        }
    }
}
