//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a fast reconnected stage for the WebRTC coordinator
    /// state machine.
    /// - Parameter context: The context for the fast reconnected stage.
    /// - Returns: A `FastReconnectedStage` instance representing the fast
    ///   reconnected state of the WebRTC coordinator.
    static func fastReconnected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        FastReconnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the fast reconnected stage in the WebRTC coordinator state
    /// machine.
    final class FastReconnectedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        /// Initializes a new instance of `FastReconnectedStage`.
        /// - Parameter context: The context for the fast reconnected stage.
        init(
            _ context: Context
        ) { super.init(id: .fastReconnected, context: context) }

        /// Performs the transition from a previous stage to this fast
        /// reconnected stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `FastReconnectedStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.fastReconnecting`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .fastReconnecting:
                // swiftlint:disable discourage_task_init
                Task { transitionOrDisconnect(.joining(context)) }
                // swiftlint:enable discourage_task_init
                return self
            default:
                return nil
            }
        }
    }
}
