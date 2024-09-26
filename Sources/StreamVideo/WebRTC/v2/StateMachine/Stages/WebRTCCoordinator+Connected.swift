//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a connected stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the connected stage.
    /// - Returns: A `ConnectedStage` instance representing the connected state
    ///   of the WebRTC coordinator.
    static func connected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the connected stage in the WebRTC coordinator state machine.
    final class ConnectedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable
    {
        /// Initializes a new instance of `ConnectedStage`.
        /// - Parameter context: The context for the connected stage.
        init(
            _ context: Context
        ) {
            super.init(id: .connected, context: context)
        }

        /// Performs the transition from a previous stage to this connected
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `ConnectedStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.connecting`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
                Task { transitionOrDisconnect(.joining(context)) }
                return self
            default:
                return nil
            }
        }
    }
}
