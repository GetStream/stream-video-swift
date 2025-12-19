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
        private var disposableBag = DisposableBag()
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

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
                // If we got here from an unrecoverable error, we won't attempt
                // any reconnection and instead we will disconnect.
                if let apiError = error as? APIError, apiError.unrecoverable == true {
                    context.reconnectionStrategy = .disconnected
                }
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
            context.lastHealthCheckReceivedAt = nil
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                let statsAdapter = await context
                    .coordinator?
                    .stateAdapter
                    .statsAdapter
                statsAdapter?.scheduleStatsReporting()

                /// It's safe to set the `sfuAdapter` to nil, as the `scheduleStatsReporting`
                /// will collect all traces and once the delivery fails, the traces will be stored and
                /// will be delivered on the next batch of traces.
                statsAdapter?.sfuAdapter = nil

                /// We add a small delay of 100ms in oder to ensure that the internet connection state
                /// has been updated, so that when we start observing it will receive the latest and
                /// updated value.
                _ = try? await DefaultTimer
                    .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
                    .nextValue()

                statsAdapter?.sfuAdapter = nil

                observeInternetConnection()
                observeDurationInStage()
            }
        }

        /// Attempts to reconnect based on the current reconnection strategy.
        private func reconnect() async {
            do {
                switch context.reconnectionStrategy {
                case let .fast(disconnectedSince, deadline):
                    if await isFastReconnectPossible(disconnectedSince: disconnectedSince, deadline: deadline) {
                        context.fastReconnectionAttempts += 1
                        try transition?(.fastReconnecting(context))
                    } else {
                        context.fastReconnectionAttempts = 0
                        try transition?(.rejoining(context))
                    }
                case .rejoin:
                    context.fastReconnectionAttempts = 0
                    try transition?(.rejoining(context))
                case .migrate:
                    context.fastReconnectionAttempts = 0
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
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .debounce(for: 1, scheduler: processingQueue)
                .removeDuplicates()
                .receive(on: processingQueue)
                .sinkTask(storeIn: disposableBag) { [weak self] in
                    /// Trace internet connection changes
                    await self?
                        .context
                        .coordinator?
                        .stateAdapter
                        .statsAdapter?
                        .trace(.init(status: $0))

                    if $0.isAvailable {
                        await self?.reconnect()
                    }
                }
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
            timeInStageCancellable = DefaultTimer
                .publish(every: context.disconnectionTimeout)
                .receive(on: processingQueue)
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

        /// Checks if a fast reconnect is possible based on several conditions.
        ///
        /// A fast reconnect is a lightweight process to restore a connection without
        /// going through the full rejoin flow. This method evaluates whether the current
        /// state of the coordinator allows for such a reconnection.
        ///
        /// - Parameters:
        ///   - disconnectedSince: The `Date` when the disconnection occurred.
        ///   - deadline: The `TimeInterval` within which a fast reconnect must be
        ///               initiated.
        /// - Returns: `true` if a fast reconnect is possible, `false` otherwise.
        private func isFastReconnectPossible(
            disconnectedSince: Date,
            deadline: TimeInterval
        ) async -> Bool {
            guard
                // Ensure we haven't exceeded the maximum number of fast reconnection attempts.
                context.fastReconnectionAttempts < context.fastReconnectionMaxAttempts,
                // Check if the time since disconnection is within the allowed deadline.
                abs(disconnectedSince.timeIntervalSinceNow) <= deadline,
                // Verify that the WebRTC publisher is available and in a healthy state.
                let publisher = await context.coordinator?.stateAdapter.publisher,
                publisher.isHealthy,
                // Verify that the WebRTC subscriber is available and in a healthy state.
                let subscriber = await context.coordinator?.stateAdapter.subscriber,
                subscriber.isHealthy
            else {
                // If any of the conditions are not met, fast reconnect is not possible.
                return false
            }

            // All conditions are met, so a fast reconnect is possible.
            return true
        }
    }
}
