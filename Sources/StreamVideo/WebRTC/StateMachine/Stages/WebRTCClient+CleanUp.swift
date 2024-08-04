//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func cleanUp(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        CleanUpStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class CleanUpStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .cleanUp, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
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
            Task { [weak self] in
                do {
                    guard
                        let self,
                        let client = context.client
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }
                    await client._cleanUp()
                    try transition?(.idle(context))
                } catch {
                    self?.transitionErrorOrLog(error)
                }
            }
        }
    }
}
