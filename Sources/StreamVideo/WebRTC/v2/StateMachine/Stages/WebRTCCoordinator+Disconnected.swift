//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        @unchecked Sendable {
        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private var internetObservationCancellable: AnyCancellable?
        private var timeInStageCancellable: AnyCancellable?

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
            timeInStageCancellable?.cancel()
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
            case .fastReconnecting, .fastReconnected:
                execute()
                return self
            case .rejoining:
                execute()
                return self
            case .migrated, .migrating:
                execute()
                return self
            default:
                return nil
            }
        }

        /// Executes the disconnected stage logic.
        private func execute() {
            context.sfuEventObserver = nil
            context.disconnectionSource = nil
            Task {
                let statsReporter = await context
                    .coordinator?
                    .stateAdapter
                    .statsReporter
                statsReporter?.sfuAdapter = nil

                /// We add a small delay of 100ms in oder to ensure that the internet connection state
                /// has been updated, so that when we start observing it will receive the latest and
                /// updated value.
                try? await Task.sleep(nanoseconds: 100_000_000)

                observeInternetConnection()
                observeDurationInStage()
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
                        context.flowError = nil
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
                .filter(\.isAvailable)
                .removeDuplicates()
                .sink { [weak self] _ in self?.reconnect() }
        }

        /// Observes the duration spent in the disconnected stage.
        ///
        /// This method monitors how long the user remains in the disconnected stage of
        /// the state machine. It checks if the disconnection timeout is set to a value
        /// greater than zero, and if so, it schedules a timer based on this duration.
        /// Once the timer expires, indicating the user has been disconnected for too
        /// long, a transition is triggered to handle the expired timeout. If the value is equal to zero, we
        /// will remain in the disconnected state until the connection restores or the user hangs up.
        ///
        /// - Important: The timer uses the disconnection timeout to define how long a
        ///              user can remain in a disconnected state. If the user's connection
        ///              isn't restored before the timeout expires, the state machine will
        ///              transition accordingly.
        ///
        /// - Note: The `context.disconnectionTimeout` holds the value of the timeout
        ///         duration. If the value is zero or less, no action will be taken,
        ///         meaning the user can stay disconnected indefinitely without
        ///         triggering a transition.
        private func observeDurationInStage() {
            guard context.disconnectionTimeout > 0 else {
                return
            }
            timeInStageCancellable = Foundation
                .Timer
                .publish(every: context.disconnectionTimeout, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in self?.didTimeInStageExpired() }
        }

        /// Handles the expiration of the time spent in the disconnected stage.
        ///
        /// This method is called when the timer, which monitors the user's disconnection
        /// timeout, expires. It triggers a state transition to either handle the
        /// disconnection as an error or log the issue. Specifically, it transitions to an
        /// error state by raising a `ClientError.NetworkNotAvailable` if the user's
        /// network is still not available.
        ///
        /// - Important: This method ensures that users who exceed the allowed time in the
        ///              disconnected state are transitioned out of the call, preventing
        ///              them from staying in an unrecoverable state indefinitely.
        private func didTimeInStageExpired() {
            transitionErrorOrLog(ClientError.NetworkNotAvailable())
        }
    }
}
