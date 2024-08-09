//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func rejoining(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        RejoiningStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class RejoiningStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .rejoining, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .disconnected:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                do {
                    guard let client = context.client else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    if let sfuAdapter = client.sfuAdapter {
                        sfuAdapter.sendLeaveRequest(for: client.sessionID)
                        await sfuAdapter.disconnect()
                    }

                    await client.partialCleanUp()

                    try transition?(
                        .connecting(
                            context
                        )
                    )
                } catch (let blockError) {
                    do {
                        context.disconnectionSource = .serverInitiated(
                            error: ClientError(blockError.localizedDescription)
                        )
                        try transition?(
                            .disconnected(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(blockError)
                    }
                }
            }
        }
    }
}
