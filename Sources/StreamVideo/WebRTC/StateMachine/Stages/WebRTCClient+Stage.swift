//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension WebRTCClient.StateMachine {
    class Stage: StreamStateMachineStage {

        struct Context {            
            weak var client: WebRTCClient?
            var callSettings: CallSettings?
            var audioSettings: AudioSettings?
            var videoOptions: VideoOptions
            var connectOptions: ConnectOptions?
            var fastReconnectDeadlineSeconds: TimeInterval
            var reconnectionStrategy: ReconnectionStrategy = .unknown
            var disconnectionSource: WebSocketConnectionState.DisconnectionSource?

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
            case idle
            case connecting
            case connected
            case joining
            case joined
            case leaving
            case cleanUp
            case disconnected
            case fastReconnecting
            case fastReconnected
            case rejoining
            case migrating
            case migrated
            case error
        }

        /// The identifier for the current stage.
        let id: ID

        /// A weak reference to the associated `Call` object.
        var context: Context

        /// The transition closure for the stage.
        var transition: Transition?

        /// Initializes a new stage with the given identifier and call.
        ///
        /// - Parameters:
        ///   - id: The identifier for the stage.
        ///   - call: The associated `Call` object.
        init(id: ID, context: Context) {
            self.id = id
            self.context = context
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            nil // No-op
        }

        func transitionErrorOrLog(_ error: Error) {
            do {
                try transition?(
                    .error(
                        context,
                        error: error
                    )
                )
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }

        func transitionOrError(_ nextStage: Stage) {
            do {
                try transition?(nextStage)
            } catch {
                transitionErrorOrLog(error)
            }
        }
    }
}

enum ReconnectionStrategy: Equatable {
    case unknown
    case disconnected
    case fast(disconnectedSince: Date, deadline: TimeInterval)
    case rejoin
    case migrate
}
