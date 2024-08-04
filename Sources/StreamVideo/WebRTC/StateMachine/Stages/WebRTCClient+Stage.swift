//
//  WebRTCClient+Stage.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 1/8/24.
//

extension WebRTCClient.StateMachine {
    class Stage: StreamStateMachineStage {

        struct Context {
            weak var client: WebRTCClient?
//            var callAuthenticator: CallAuthenticator
//            var sfuAdapter: SFUAdapter
//            var fromSFUAdapter: SFUAdapter?
//            var currentSFU: String
//            var apiKey: String
            var callSettings: CallSettings
            var audioSettings: AudioSettings?
            var videoOptions: VideoOptions
            var connectOptions: ConnectOptions?
//            var webSocketClient: WebSocketClient
//            var fastReconnectDeadlineSeconds: TimeInterval
            var reconnectionStrategy: ReconnectionStrategy = .disconnected
            var disconnectionSource: WebSocketConnectionState.DisconnectionSource?
//            var fromWebSocketClient: WebSocketClient?

            func nextReconnectionStrategy() -> ReconnectionStrategy {
                switch reconnectionStrategy {
                   case .fast:
                       return .clean(
                           callSettings: callSettings,
                           videoOptions: videoOptions,
                           connectOptions: connectOptions ?? .init(iceServers: [])
                       )
                   case let .clean(callSettings, videoOptions, connectOptions):
                       return .rejoin(
                           callSettings: callSettings,
                           videoOptions: videoOptions,
                           connectOptions: connectOptions
                       )
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
            case disconnected
            case fastReconnecting
            case fastReconnected
            case cleanReconnecting
            case cleanReconnected
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
                log.error(error)
            }
        }
    }
}

enum ReconnectionStrategy {
    case disconnected
    case fast(disconnectedSince: Date, deadline: TimeInterval)
    case clean(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    )
    case rejoin(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    )
    case migrate
}
