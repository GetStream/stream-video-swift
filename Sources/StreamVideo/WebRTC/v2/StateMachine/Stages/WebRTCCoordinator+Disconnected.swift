//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a disconnected stage for the WebRTC coordinator
    /// state machine.
    /// - Parameter context: The context for the disconnected stage.
    /// - Returns: A `DisconnectedStage` instance representing the disconnected
    ///   state of the WebRTC coordinator.
    static func disconnected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        DisconnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the disconnected stage in the WebRTC coordinator state
    /// machine.
    final class DisconnectedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable
    {
        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private var internetObservationCancellable: AnyCancellable?

        /// Initializes a new instance of `DisconnectedStage`.
        /// - Parameter context: The context for the disconnected stage.
        init(
            _ context: Context
        ) {
            super.init(id: .disconnected, context: context)
        }

        /// Performs cleanup actions before transitioning away from this stage.
        override func willTransitionAway() {
            internetObservationCancellable?.cancel()
            context.disconnectionSource = nil
            context.flowError = nil
        }

        /// Performs the transition from a previous stage to this disconnected
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `DisconnectedStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.joining`, `.joined`,
        ///   `.disconnected`, `.fastReconnecting`, `.rejoining`
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

        /// Executes the disconnected stage logic.
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

        /// Attempts to reconnect based on the current reconnection strategy.
        private func reconnect() {
            do {
                switch context.reconnectionStrategy {
                case let .fast(disconnectedSince, deadline) where abs(disconnectedSince.timeIntervalSinceNow) <= deadline:
                    try transition?(.fastReconnecting(context))
                case .fast, .rejoin:
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

        /// Observes internet connection status and triggers reconnection when
        /// available.
        private func observeInternetConnection() {
            internetObservationCancellable?.cancel()
            internetObservationCancellable = internetConnectionObserver
                .statusPublisher
                .receive(on: DispatchQueue.main)
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .filter { $0.isAvailable }
                .removeDuplicates()
                .sink { [weak self] _ in self?.reconnect() }
        }
    }
}
