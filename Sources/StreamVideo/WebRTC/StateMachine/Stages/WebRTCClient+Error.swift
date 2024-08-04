//
//  WebRTCClient+Error.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 1/8/24.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    /// Creates an error stage for the provided call with the specified error.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - error: The error associated with the stage.
    /// - Returns: An `ErrorStage` instance.
    static func error(
        _ context: Context,
        error: Error
    ) -> WebRTCClient.StateMachine.Stage {
        ErrorStage(
            context,
            error: error
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    /// A class representing the error stage in the `StreamCallStateMachine`.
    final class ErrorStage: WebRTCClient.StateMachine.Stage {
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
        ///
        /// - Valid Transitions:
        ///   - From: `JoiningStage`, `AcceptingStage`, `RejectingStage`
        ///   - To: `IdleStage`
        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            Task { [error] in
                do {
                    try transition?(.idle(context))
                    log.error(error)
                } catch {
                    log.error(error)
                }
            }
            return self
        }
    }
}

