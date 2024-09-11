//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func disconnected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        DisconnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class DisconnectedStage: WebRTCCoordinator.StateMachine.Stage {

        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private var internetObservationCancellable: AnyCancellable?

        init(
            _ context: Context
        ) {
            super.init(id: .disconnected, context: context)
        }

        override func willTransitionAway() {
            internetObservationCancellable?.cancel()
            context.disconnectionSource = nil
            context.flowError = nil
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            if let source = context.disconnectionSource {
                log.error(
                    "WebSocket disconnected from \(previousStage.id) due to \(source).",
                    subsystems: .webRTC
                )
            } else if let error = context.flowError {
                log.error(
                    "Disconnected from \(previousStage.id) due to \(error).",
                    subsystems: .webRTC
                )
            }

            switch previousStage.id {
            case .connecting:
                execute()
                return self
            case .joining:
                execute()
                return self
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
            case .migrated:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            context.sfuEventObserver = nil
            Task {
                let statsReporter = await context
                    .coordinator?
                    .stateAdapter
                    .statsReporter
                statsReporter?.sfuAdapter = nil
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
                    try transition?(.migrating(context))

                case .unknown:
                    if let error = context.flowError {
                        try transition?(.error(context, error: error))
                    } else {
                        try transition?(.leaving(context))
                    }

                case .disconnected:
                    try transition?(.leaving(context))
                }
            } catch let (blockError) {
                if context.reconnectionStrategy == .disconnected {
                    transitionErrorOrLog(blockError)
                } else {
                    transitionOrDisconnect(.disconnected(context))
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
