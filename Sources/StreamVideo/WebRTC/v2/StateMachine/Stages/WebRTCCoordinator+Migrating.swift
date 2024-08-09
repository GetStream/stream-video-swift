//
//  WebRTCCoordinator+Migrating.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
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
                        await context
                            .coordinator?
                            .stateAdapter
                            .cleanUpForReconnection()

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

                        try await context
                            .coordinator?
                            .stateAdapter
                            .didUpdate(sfuAdapter: nil)

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

