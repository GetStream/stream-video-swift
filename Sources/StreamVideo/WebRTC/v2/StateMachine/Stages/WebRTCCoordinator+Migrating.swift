//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a migrating stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the migrating stage.
    /// - Returns: A `MigratingStage` instance representing the migrating state
    ///   of the WebRTC coordinator.
    static func migrating(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        MigratingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the migrating stage in the WebRTC coordinator state machine.
    final class MigratingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `MigratingStage`.
        /// - Parameter context: The context for the migrating stage.
        init(
            _ context: Context
        ) {
            super.init(id: .migrating, context: context)
        }

        /// Performs the transition from a previous stage to this migrating
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `MigratingStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.disconnected`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .disconnected:
                Task(disposableBag: disposableBag) { [weak self] in
                    guard let self else { return }
                    do {
                        guard context.coordinator != nil else {
                            throw ClientError(
                                "WebRCTCoordinator instance not available."
                            )
                        }

                        try Task.checkCancellation()

                        context.previousSessionPublisher = await context
                            .coordinator?
                            .stateAdapter
                            .publisher

                        try Task.checkCancellation()

                        context.previousSessionSubscriber = await context
                            .coordinator?
                            .stateAdapter
                            .subscriber

                        try Task.checkCancellation()

                        context.previousSFUAdapter = await context
                            .coordinator?
                            .stateAdapter
                            .sfuAdapter

                        context.sfuEventObserver?.stopObserving()
                        context.sfuEventObserver = nil
                        context.migratingFromSFU = context.currentSFU
                        context.currentSFU = ""

                        try Task.checkCancellation()

                        await context
                            .coordinator?
                            .stateAdapter
                            .cleanUpForReconnection()

                        transitionOrDisconnect(.migrated(context))
                    } catch {
                        transitionDisconnectOrError(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
