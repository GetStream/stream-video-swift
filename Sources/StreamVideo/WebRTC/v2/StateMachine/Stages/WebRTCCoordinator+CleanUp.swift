//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func cleanUp(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        CleanUpStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class CleanUpStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .cleanUp, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                return nil
            default:
                execute()
                return self
            }
        }

        private func execute() {
            context.sfuEventObserver = nil
            Task { [weak self] in
                do {
                    guard
                        let self,
                        let coordinator = context.coordinator
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

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
