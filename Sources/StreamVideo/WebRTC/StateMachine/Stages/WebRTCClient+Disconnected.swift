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
            if let source = context.disconnectionSource {
                log.error(
                    "Disconnected from \(previousStage.id) due to \(source).",
                    subsystems: .webRTC
                )
            }

            switch previousStage.id {
            case .joined:
                execute()
                return self
            case .disconnected:
                execute()
                return self
            case .fastReconnecting:
                execute()
                return self
            case .rejoining:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                observeInternetConnection()
            }
        }

        private func reconnect() {
            do {
                switch context.reconnectionStrategy {
                case let .fast(disconnectedSince, deadline) where disconnectedSince.timeIntervalSinceNow <= deadline:
                    try transition?(
                        .fastReconnecting(
                            context
                        )
                    )
                case .fast:
                    try transition?(.rejoining(context))

                case .rejoin:
                    try transition?(.rejoining(context))

                case .migrate:
                    break

                case .unknown:
                    break

                case .disconnected:
                    break
                }
            } catch (let blockError) {
                if context.reconnectionStrategy == .disconnected {
                    transitionErrorOrLog(blockError)
                } else {
                    do {
                        try transition?(
                            .disconnected(context)
                        )
                    } catch {
                        transitionErrorOrLog(blockError)
                    }
                }
            }
        }

        private func observeInternetConnection() {
            internetObservationCancellable?.cancel()
            internetObservationCancellable = internetConnectionObserver
                .$status
                .receive(on: DispatchQueue.main)
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .filter { $0.isAvailable }
                .removeDuplicates()
                .sink { [weak self] _ in self?.reconnect() }
        }
    }
}
