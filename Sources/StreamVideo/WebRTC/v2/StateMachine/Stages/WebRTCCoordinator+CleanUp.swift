//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a clean-up stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the clean-up stage.
    /// - Returns: A `CleanUpStage` instance representing the clean-up state of
    ///   the WebRTC coordinator.
    static func cleanUp(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        CleanUpStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the clean-up stage in the WebRTC coordinator state machine.
    final class CleanUpStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `CleanUpStage`.
        /// - Parameter context: The context for the clean-up stage.
        init(
            _ context: Context
        ) {
            super.init(id: .cleanUp, context: context)
        }

        /// Performs the transition from a previous stage to this clean-up
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `CleanUpStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: all stages except `.idle` and
        ///   `.cleanUp`.
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                return nil
            case .cleanUp:
                return nil
            default:
                execute()
                return self
            }
        }

        /// Executes the clean-up process.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                do {
                    guard
                        let self,
                        let coordinator = context.coordinator
                    else {
                        throw ClientError("WebRCTCoordinator instance not available.")
                    }

                    try Task.checkCancellation()

                    context.sfuEventObserver = nil

                    await coordinator.stateAdapter.cleanUp()
                    context = .init(coordinator: context.coordinator)

                    try transition?(.idle(context))
                } catch {
                    self?.transitionErrorOrLog(error)
                }
            }
        }
    }
}
