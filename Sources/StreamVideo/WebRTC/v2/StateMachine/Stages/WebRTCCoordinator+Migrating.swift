//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension WebRTCCoordinator.StateMachine.Stage {

    static func migrating(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        MigratingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class MigratingStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .migrating, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .disconnected:
                Task {
                    do {
                        context.previousSessionPublisher = await context
                            .coordinator?
                            .stateAdapter
                            .publisher

                        context.previousSessionSubscriber = await context
                            .coordinator?
                            .stateAdapter
                            .subscriber

                        context.previousSFUAdapter = await context
                            .coordinator?
                            .stateAdapter
                            .sfuAdapter

                        await context
                            .coordinator?
                            .stateAdapter
                            .cleanUpForReconnection()

                        context.sfuEventObserver = nil

                        context.migratingFromSFU = context.currentSFU

                        try transition?(
                            .migrated(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
