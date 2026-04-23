//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine {
    /// Represents a stage in the WebRTC coordinator state machine.
    class Stage: StreamStateMachineStage, @unchecked Sendable {

        /// Context holding the state and dependencies for the stage.
        struct Context: @unchecked Sendable {
            weak var coordinator: WebRTCCoordinator?
            var authenticator: WebRTCAuthenticating = WebRTCAuthenticator()
            var sfuEventObserver: SFUEventAdapter?
            var reconnectAttempts: UInt32 = 0
            var currentSFU: String = ""
            var fastReconnectDeadlineSeconds: TimeInterval = 0
            var disconnectionTimeout: TimeInterval = 0
            var reportingIntervalMs: TimeInterval = 0
            var reconnectionStrategy: ReconnectionStrategy = .unknown
            var disconnectionSource: WebSocketConnectionState.DisconnectionSource?
            var flowError: Error?
            var joinSource: JoinSource?
            var joinPolicy: WebRTCJoinPolicy = .default
            /// Preserves explicit join routing hints for recovery requests that
            /// no longer carry the original `CreateCallOptions`.
            var highScaleLivestreamPublisherHint: Bool?
            /// Shared adapter handling SFU track subscriptions updates across
            /// stage transitions.
            var updateSubscriptionsAdapter: WebRTCUpdateSubscriptionsAdapter?

            /// Observes SFU-full events for the active adapter so we can force
            /// migration immediately when the current SFU has no capacity.
            var sfuFullObserver: WebRTCSFUFullObserver?

            var audioSessionWatchdog: WebRTCAudioSessionWatchdog = .init()

            var isRejoiningFromSessionID: String?
            var migratingFromSFU: String = ""
            /// Tracks all SFUs rejected during migration attempts so retries can
            /// explicitly avoid already exhausted edges.
            var migratingFromList: [String] = []
            var migrationStatusObserver: WebRTCMigrationStatusObserver?
            var previousSessionPublisher: RTCPeerConnectionCoordinator?
            var previousSessionSubscriber: RTCPeerConnectionCoordinator?
            var previousSFUAdapter: SFUAdapter?

            // https://www.notion.so/stream-wiki/Improved-Reconnects-and-ICE-connection-handling-2186a5d7f9f680c29236c2c37cfa11a3?source=copy_link#2186a5d7f9f68088a9b1d6ecf67e5aad
            var fastReconnectionMaxAttempts: Int = 3
            var fastReconnectionAttempts: Int = 0
            /// Maximum number of `.rejoin` transitions allowed inside the
            /// rolling `rejoinAttemptWindow`.
            ///
            /// This is intentionally a burst guard, not a lifetime cap. The
            /// goal is to stop pathological loops that keep issuing backend
            /// `joinCall` requests in a short period of time after unstable
            /// disconnects, while still allowing long-running calls to recover
            /// from occasional isolated rejoin events.
            ///
            /// Example:
            /// - If 10 rejoins happen within 2 minutes, the 11th rejoin
            ///   inside that same 2-minute window is rejected.
            /// - If rejoins are 6 minutes apart, older attempts have already
            ///   aged out of the rolling window before the next one happens, so
            ///   each rejoin is treated as an isolated recovery and is allowed.
            var rejoinMaxAttempts: Int = 10
            /// Size of the rolling window used by `rejoinMaxAttempts`.
            ///
            /// Only rejoin attempts whose timestamps are newer than
            /// `now - rejoinAttemptWindow` count toward the limit.
            var rejoinAttemptWindow: TimeInterval = 120
            /// Timestamps for recent rejoin attempts that are still inside the
            /// rolling window.
            ///
            /// Entries older than `rejoinAttemptWindow` are pruned before each
            /// new rejoin decision, so the array models "recent rejoin burst
            /// pressure" rather than "all rejoins since the call started".
            var rejoinAttemptTimestamps: [Date] = []

            var healthCheckInterval: TimeInterval = 5
            var webSocketHealthTimeout: TimeInterval = 15
            var lastHealthCheckReceivedAt: Date?

            /// Stores the initial join response so the pending ``Call.join()``
            /// completion can be finished once the SFU handshake succeeds.
            var initialJoinCallResponse: JoinCallResponse?

            /// Completes the pending ``Call.join()`` continuation with either
            /// success or failure depending on stage flow outcome.
            var joinResponseHandler: PassthroughSubject<JoinCallResponse, Error>?

            /// Determines the next reconnection strategy based on the current one.
            /// - Returns: The next reconnection strategy.
            func nextReconnectionStrategy() -> ReconnectionStrategy {
                switch reconnectionStrategy {
                case .fast:
                    return .rejoin
                default:
                    return reconnectionStrategy
                }
            }

            /// Builds the minimal options payload used when recovery
            /// authentication no longer has the original join options.
            func recoveryJoinOptions() -> CreateCallOptions? {
                guard let hint = highScaleLivestreamPublisherHint else {
                    return nil
                }
                return .init(highScaleLivestreamPublisherHint: hint)
            }

            /// Registers a rejoin attempt if the rolling rejoin limit has not
            /// been reached yet.
            ///
            /// Before checking the limit, this prunes any timestamps that are
            /// older than `rejoinAttemptWindow`.
            ///
            /// This means the limit is evaluated against only recent activity.
            /// Rejoins that happened far enough in the past stop counting.
            ///
            /// Example with the default configuration:
            /// - Window: 120 seconds
            /// - Max attempts: 10
            /// - 10 attempts inside the last 120 seconds consume the full
            ///   budget, so the 11th attempt inside that same window is
            ///   rejected.
            /// - A later rejoin at `06:00` is allowed, because all prior
            ///   timestamps are outside the 120-second window and are pruned
            ///   first.
            ///
            /// - Parameter date: The date of the attempted rejoin.
            /// - Returns: `true` when the attempt is allowed, otherwise `false`.
            mutating func registerRejoinAttempt(
                at date: Date = .init()
            ) -> Bool {
                let cutoff = date.addingTimeInterval(-rejoinAttemptWindow)
                rejoinAttemptTimestamps = rejoinAttemptTimestamps.filter {
                    $0 >= cutoff
                }

                guard rejoinAttemptTimestamps.count < rejoinMaxAttempts else {
                    return false
                }

                rejoinAttemptTimestamps.append(date)
                return true
            }
        }

        /// Enumeration of possible stage identifiers.
        enum ID: Hashable, CaseIterable {
            case idle, connecting, connected, joining, joined, leaving, cleanUp,
                 disconnected, fastReconnecting, fastReconnected, rejoining,
                 migrating, migrated, error, blocked, peerConnectionPreparing
        }

        /// The identifier for the current stage.
        let id: ID

        let container: String = "WebRTC"

        /// The context for the current stage.
        var context: Context

        /// The transition closure for the stage.
        var transition: Transition?

        /// Timestamp used to report how long this stage stayed active.
        var enteredAt = Date()

        /// Initializes a new stage with the given identifier and context.
        /// - Parameters:
        ///   - id: The identifier for the stage.
        ///   - context: The context for the stage.
        init(id: ID, context: Context) {
            self.id = id
            self.context = context
        }

        /// Called before transitioning away from this stage.
        func willTransitionAway() {
            if let stateAdapter = context.coordinator?.stateAdapter {
                let trace = WebRTCTrace(self, enteredAt: enteredAt)
                Task { [weak stateAdapter] in
                    await stateAdapter?.trace(trace)
                }
            }
        }

        /// Called after transitioning away from this stage.
        func didTransitionAway() { /* No-op */ }

        /// Handles the transition from the previous stage to this stage.
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            nil // No-op
        }

        // MARK: - Helper transitions

        /// Attempts to transition to an error state or logs the error if transition fails.
        /// - Parameter error: The error that occurred.
        func transitionErrorOrLog(_ error: Error) {
            do {
                try transition?(.error(context, error: error))
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }

        /// Attempts to transition to a disconnected state or an error state.
        /// - Parameter error: The error that occurred.
        func transitionDisconnectOrError(
            _ error: Error,
            ignoresCancellationError: Bool = true
        ) {
            guard (error as? CancellationError) == nil else {
                return
            }
            context.flowError = error
            transitionOrError(.disconnected(context))
        }

        /// Attempts to transition to the next stage or to an error state if transition fails.
        /// - Parameter nextStage: The next stage to transition to.
        func transitionOrError(_ nextStage: Stage) {
            do {
                try transition?(nextStage)
            } catch {
                transitionErrorOrLog(error)
            }
        }

        /// Attempts to transition to the next stage or to a disconnected state if transition fails.
        /// - Parameter nextStage: The next stage to transition to.
        func transitionOrDisconnect(_ nextStage: Stage) {
            do {
                try transition?(nextStage)
            } catch let initialError {
                nextStage.context.flowError = initialError
                transitionOrError(.disconnected(nextStage.context))
            }
        }

        /// Notifies any pending ``Call.join()`` caller with the initial join
        /// response
        /// and clears pending completion state.
        func reportJoinCompletion() {
            guard
                let joinCallResponse = context.initialJoinCallResponse,
                let joinResponseHandler = context.joinResponseHandler
            else {
                return
            }

            joinResponseHandler.send(joinCallResponse)

            // Clean up
            context.initialJoinCallResponse = nil
            context.joinResponseHandler = nil
        }
    }

    /// Represents different strategies for reconnection.
    enum ReconnectionStrategy: Equatable {
        case unknown, disconnected, fast(disconnectedSince: Date, deadline: TimeInterval),
             rejoin, migrate

        /// Determines the next reconnection strategy based on the current one.
        var next: ReconnectionStrategy {
            switch self {
            case .unknown, .disconnected:
                return .disconnected
            case .fast:
                return .rejoin
            case .rejoin, .migrate:
                return self
            }
        }

        /// Initializes a new reconnection strategy based on the SFU model and fast reconnect deadline.
        /// - Parameters:
        ///   - strategy: The SFU model's websocket reconnect strategy.
        ///   - fastReconnectDeadlineSeconds: The deadline for fast reconnection in seconds.
        init(
            from strategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy,
            fastReconnectDeadlineSeconds: TimeInterval
        ) {
            switch strategy {
            case .fast:
                self = .fast(disconnectedSince: Date(), deadline: fastReconnectDeadlineSeconds)
            case .rejoin:
                self = .rejoin
            case .migrate:
                self = .migrate
            case .disconnect:
                self = .disconnected
            default:
                self = .rejoin
            }
        }
    }
}
