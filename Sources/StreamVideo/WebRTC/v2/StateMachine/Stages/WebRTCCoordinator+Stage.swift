//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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

            var isRejoiningFromSessionID: String?
            var migratingFromSFU: String = ""
            var migrationStatusObserver: WebRTCMigrationStatusObserver?
            var previousSessionPublisher: RTCPeerConnectionCoordinator?
            var previousSessionSubscriber: RTCPeerConnectionCoordinator?
            var previousSFUAdapter: SFUAdapter?

            // https://www.notion.so/stream-wiki/Improved-Reconnects-and-ICE-connection-handling-2186a5d7f9f680c29236c2c37cfa11a3?source=copy_link#2186a5d7f9f68088a9b1d6ecf67e5aad
            var fastReconnectionMaxAttempts: Int = 3
            var fastReconnectionAttempts: Int = 0

            var healthCheckInterval: TimeInterval = 5
            var webSocketHealthTimeout: TimeInterval = 15
            var lastHealthCheckReceivedAt: Date?

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
        }

        /// Enumeration of possible stage identifiers.
        enum ID: Hashable, CaseIterable {
            case idle, connecting, connected, joining, joined, leaving, cleanUp,
                 disconnected, fastReconnecting, fastReconnected, rejoining,
                 migrating, migrated, error, blocked
        }

        /// The identifier for the current stage.
        let id: ID

        let container: String = "WebRTC"

        /// The context for the current stage.
        var context: Context

        /// The transition closure for the stage.
        var transition: Transition?

        /// Initializes a new stage with the given identifier and context.
        /// - Parameters:
        ///   - id: The identifier for the stage.
        ///   - context: The context for the stage.
        init(id: ID, context: Context) {
            self.id = id
            self.context = context
        }

        /// Called before transitioning away from this stage.
        func willTransitionAway() { /* No-op */ }

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
