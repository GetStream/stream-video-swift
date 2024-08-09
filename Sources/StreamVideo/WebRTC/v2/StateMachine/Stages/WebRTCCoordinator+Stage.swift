//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine {
    class Stage: StreamStateMachineStage, @unchecked Sendable {

        struct Context {            
            weak var coordinator: WebRTCCoordinator?
            var reconnectAttempts: UInt32 = 0
            var isRejoiningFromSessionID: String? = nil
            var currentSFU: String = ""
            var migratingFromSFU: String = ""
            var fastReconnectDeadlineSeconds: TimeInterval = 0
            var reconnectionStrategy: ReconnectionStrategy = .unknown
            var disconnectionSource: WebSocketConnectionState.DisconnectionSource? = nil

            var previousSessionPublisher: RTCPeerConnectionCoordinator?
            var previousSessionSubscriber: RTCPeerConnectionCoordinator?
            var previousSFUAdapter: SFUAdapter?

            var sfuEventObserver: SFUEventAdapter?

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
            from previousStage: WebRTCCoordinator.StateMachine.Stage
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

    enum ReconnectionStrategy: Equatable {
        case unknown
        case disconnected
        case fast(disconnectedSince: Date, deadline: TimeInterval)
        case rejoin
        case migrate
    }
}

extension WebRTCCoordinator.StateMachine.Stage {
    struct Authenticator {

        func authenticate(
            coordinator: WebRTCCoordinator,
            currentSFU: String?,
            create: Bool
        ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse) {
            let response = try await coordinator
                .callAuthenticator
                .authenticate(
                    create: create,
                    migratingFrom: currentSFU
                )

            await coordinator.stateAdapter.set(
                token: response.credentials.token
            )
            await coordinator.stateAdapter.set(Set(response.ownCapabilities))
            await coordinator.stateAdapter.set(response.call.settings.audio)
            await coordinator.stateAdapter.set(
                ConnectOptions(
                    iceServers: response.credentials.iceServers
                )
            )
            if await coordinator.stateAdapter.callSettings == .init() {
                await coordinator.stateAdapter.set(
                    response.call.settings.toCallSettings
                )
            }
            await coordinator.stateAdapter.set(
                VideoOptions(
                    targetResolution: response.call.settings.video.targetResolution
                )
            )

            let sfuAdapter = SFUAdapter(
                serviceConfiguration: .init(
                    url: .init(string: response.credentials.server.url)!,
                    apiKey: coordinator.stateAdapter.apiKey,
                    token: await coordinator.stateAdapter.token
                ),
                webSocketConfiguration: .init(
                    url: .init(string: response.credentials.server.wsEndpoint)!,
                    eventNotificationCenter: .init()
                )
            )

            let statsReporter = await coordinator.stateAdapter.statsReporter
            statsReporter?.interval = TimeInterval(
                response.statsOptions.reportingIntervalMs / 1000
            )

            return (sfuAdapter, response)
        }

        func connect(sfuAdapter: SFUAdapter) async throws {
            sfuAdapter.connect()
            _ = try await sfuAdapter
                .$connectionState
                .filter {
                    switch $0 {
                    case .authenticating:
                        return true
                    default:
                        return false
                    }
                }
                .nextValue(timeout: 5)
        }
    }
}
