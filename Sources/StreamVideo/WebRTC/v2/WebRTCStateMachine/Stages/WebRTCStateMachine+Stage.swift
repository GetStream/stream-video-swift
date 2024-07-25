//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine {
    class Stage: StreamStateMachineStage {

        /// Enumeration of possible stage identifiers.
        enum ID: Hashable, CaseIterable {
            case idle
            case connecting
            case connected
            case joining
            case joined
            case leaving
            case disconnected
            case fastReconnecting
            case fastReconnected
            case cleanReconnecting
            case cleanReconnected
            case rejoining
            case migrating
            case migrated
            case error
        }

        /// The identifier for the current stage.
        let id: ID

        /// A weak reference to the associated `Call` object.
        weak var coordinator: WebRTCCoordinator?

        /// The transition closure for the stage.
        var transition: Transition?

        /// Initializes a new stage with the given identifier and call.
        ///
        /// - Parameters:
        ///   - id: The identifier for the stage.
        ///   - call: The associated `Call` object.
        init(id: ID, coordinator: WebRTCCoordinator?) {
            self.id = id
            self.coordinator = coordinator
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            nil // No-op
        }

        func transitionErrorOrLog(_ error: Error) {
            do {
                try transition?(
                    .error(
                        coordinator,
                        error: error
                    )
                )
            } catch {
                log.error(error)
            }
        }
    }
}
