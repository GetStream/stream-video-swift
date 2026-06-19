//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a leaving stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the leaving stage.
    /// - Returns: A `LeavingStage` instance representing the leaving state of
    ///   the WebRTC coordinator.
    static func blocked(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        BlockedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the leaving stage in the WebRTC coordinator state machine.
    final class BlockedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `BlockedStage`.
        /// - Parameter context: The context for the leaving stage.
        init(
            _ context: Context
        ) {
            super.init(id: .blocked, context: context)
        }

        /// Performs the transition from a previous stage to this leaving stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `BlockedStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: `.joined`, `.disconnected`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .cleanUp, .leaving, .error, .idle:
                // We do nothing in those as the user isn't in the call
                return nil
            default:
                execute()
                return self
            }
        }

        /// Executes the leaving process.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    guard
                        context.coordinator != nil
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    try Task.checkCancellation()

                    try transition?(.cleanUp(context))
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
