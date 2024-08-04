//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func fastReconnecting(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        FastReconnectingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class FastReconnectingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .fastReconnecting, context: context)
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
                    context.webSocketClient.connect()

                    _ = try await context
                        .webSocketClient
                        .connectionSubject
                        .filter {
                            switch $0 {
                            case .authenticating:
                                return true
                            default:
                                return false
                            }
                        }
                        .nextValue(timeout: 15)

                    try transition?(
                        .fastReconnected(
                            context
                        )
                    )
                } catch {
                    do {
                        context.reconnectionStrategy = context.nextReconnectionStrategy()
                        context.disconnectionSource = .serverInitiated(error: ClientError(error.localizedDescription))
                        
                        try transition?(
                            .disconnected(context)
                        )

//                        try transition?(
//                            .disconnected(
//                                coordinator,
//                                sfuAdapter: sfuAdapter,
//                                callSettings: callSettings,
//                                videoOptions: videoOptions,
//                                connectOptions: connectOptions,
//                                disconnectionSource: .serverInitiated(error: ClientError(error.localizedDescription)),
//                                reconnectionStrategy: { [reconnectionStrategy, callSettings, videoOptions, connectOptions] in
//                                    switch reconnectionStrategy {
//                                    case .fast:
//                                        return .clean(
//                                            callSettings: callSettings,
//                                            videoOptions: videoOptions,
//                                            connectOptions: connectOptions
//                                        )
//                                    case let .clean(callSettings, videoOptions, connectOptions):
//                                        return .rejoin(
//                                            callSettings: callSettings,
//                                            videoOptions: videoOptions,
//                                            connectOptions: connectOptions
//                                        )
//                                    default:
//                                        return reconnectionStrategy
//                                    }
//                                }()
//                            )
//                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }
    }
}
