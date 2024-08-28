//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func leaving(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        LeavingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class LeavingStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .leaving, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let coordinator = context.coordinator,
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    sfuAdapter.sendLeaveRequest(
                        for: await coordinator.stateAdapter.sessionID
                    )
                    // TODO: further cleanup
                    try transition?(.cleanUp(context))
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
