//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns an idle stage for the WebRTC coordinator state machine.
    /// - Parameter context: The context for the idle stage.
    /// - Returns: An `IdleStage` instance representing the idle state of the
    ///   WebRTC coordinator.
    static func idle(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        IdleStage(context)
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the idle stage in the WebRTC coordinator state machine.
    final class IdleStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        /// Convenience initializer for creating an `IdleStage`.
        /// - Parameter context: The context for the idle stage.
        convenience init(_ context: Context) {
            self.init(id: .idle, context: context)
        }

        /// Performs the transition from a previous stage to this idle stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `IdleStage` instance, indicating a successful
        ///   transition to the idle state.
        /// - Note: Any other stage can be transitioned to `idle`.
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            self
        }
    }
}
