//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func disconnected(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        DisconnectedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class DisconnectedStage: WebRTCClient.StateMachine.Stage {

        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private var internetObservationCancellable: AnyCancellable?

        init(
            _ context: Context
        ) {
            super.init(id: .disconnected, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined:
                Task {
                    // We need the task to ensure any transition will happen after
                    // this one has completed.
                    execute()
                }
                return self
            default:
                return nil
            }
        }

        private func execute() {
            guard
                case .available = internetConnectionObserver.status
            else {
                observeInternetConnection()
                return
            }

            reconnect()
        }

        private func reconnect() {
            do {
                switch context.reconnectionStrategy {
                case .disconnected:
                    break

                case let .fast(disconnectedSince, deadline) where disconnectedSince.timeIntervalSinceNow <= deadline:
                    try transition?(
                        .fastReconnecting(
                            context
                        )
                    )
                case .fast:
                    try transition?(
                        .cleanReconnecting(
//                            coordinator,
//                            callSettings: callSettings,
//                            videoOptions: videoOptions,
//                            connectOptions: connectOptions,
//                            disconnectionSource: disconnectionSource,
//                            reconnectionStrategy: .clean(
//                                callSettings: callSettings,
//                                videoOptions: videoOptions,
//                                connectOptions: connectOptions
//                            )
                            context
                        )
                    )
                case let .clean(callSettings, videoOptions, connectOptions):
                    try transition?(
                        .cleanReconnecting(
//                            coordinator,
//                            callSettings: callSettings,
//                            videoOptions: videoOptions,
//                            connectOptions: connectOptions,
//                            disconnectionSource: disconnectionSource,
//                            reconnectionStrategy: .clean(
//                                callSettings: callSettings,
//                                videoOptions: videoOptions,
//                                connectOptions: connectOptions
//                            )
                            context
                        )
                    )
                case let .rejoin(callSettings, videoOptions, connectOptions):
                    try transition?(
                        .rejoining(
                            context
                        )
                    )
                case .migrate:
                    break
                }
            } catch {
                transitionErrorOrLog(error)
            }
        }

        private func observeInternetConnection() {
            internetObservationCancellable?.cancel()
            internetObservationCancellable = internetConnectionObserver
                .publisher
                .filter { $0.isAvailable }
                .sink { [weak self] _ in self?.execute() }
        }
    }
}
