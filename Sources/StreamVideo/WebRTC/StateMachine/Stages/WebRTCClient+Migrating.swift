//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension WebRTCClient.StateMachine.Stage {

    static func migrating(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        MigratingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class MigratingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .migrating, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined:
                Task {
                    do {
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
