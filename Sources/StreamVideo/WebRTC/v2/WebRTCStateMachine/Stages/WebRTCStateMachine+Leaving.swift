//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine.Stage {

    static func leaving(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter
    ) -> WebRTCStateMachine.Stage {
        LeavingStage(
            coordinator,
            sfuAdapter: sfuAdapter
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class LeavingStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter
        ) {
            self.sfuAdapter = sfuAdapter
            super.init(id: .leaving, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
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
            Task {
                do {
                    guard let coordinator else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }
                    sfuAdapter.notifyLeave(
                        sessionId: coordinator.authenticationAdapter.sessionId,
                        reason: ""
                    )

                    sfuAdapter.disconnect()
                    // TODO: further cleanup

                    try transition?(.idle(coordinator))
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
