//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func leaving(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        LeavingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class LeavingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .leaving, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
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
                        let client = context.client
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    client.sfuAdapter.sendLeaveRequest(
                        for: client.sessionID
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
