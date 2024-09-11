//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a connecting stage for the WebRTC coordinator state
    /// machine.
    /// - Parameters:
    ///   - context: The context for the connecting stage.
    ///   - ring: A Boolean indicating whether to ring the other participants.
    /// - Returns: A `ConnectingStage` instance representing the connecting
    ///   state of the WebRTC coordinator.
    static func connecting(
        _ context: Context,
        ring: Bool
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectingStage(
            context,
            ring: ring
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the connecting stage in the WebRTC coordinator state machine.
    final class ConnectingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable
    {
        /// Indicates whether to ring the other participants.
        private let ring: Bool

        /// Initializes a new instance of `ConnectingStage`.
        /// - Parameters:
        ///   - context: The context for the connecting stage.
        ///   - ring: A Boolean indicating whether to ring other participants.
        init(
            _ context: Context,
            ring: Bool
        ) {
            self.ring = ring
            super.init(id: .connecting, context: context)
        }

        /// Performs the transition from a previous stage to this connecting
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `ConnectingStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.idle`,  `.rejoining`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute(create: true, updateSession: false)
                return self
            case .rejoining:
                execute(create: false, updateSession: true)
                return self
            default:
                return nil
            }
        }

        /// Executes the call connecting process.
        /// - Parameters:
        ///   - create: A Boolean indicating whether to create a new session.
        ///   - updateSession: A Boolean indicating whether to update the
        ///     existing session.
        private func execute(create: Bool, updateSession: Bool) {
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let coordinator = context.coordinator
                    else {
                        throw ClientError("WebRTCCoordinator instance not available in stage id:\(id).")
                    }

                    if updateSession {
                        /// By refreshing the session, we are asking the stateAdapter to update
                        /// the sessionId to a new one.
                        await coordinator.stateAdapter.refreshSession()
                    }

                    /// The authenticator will fetch a ``JoinCallResponse`` and will use it to
                    /// create an ``SFUAdapter`` instance that we can later use in our flow.
                    let (sfuAdapter, response) = try await context
                        .authenticator
                        .authenticate(
                            coordinator: coordinator,
                            currentSFU: nil,
                            create: create,
                            ring: ring
                        )

                    /// We provide the ``SFUAdapter`` to the authenticator which will ensure
                    /// that we will continue only when the WS `connectionState` on the
                    /// ``SFUAdapter`` has changed to `.authenticating`.
                    try await context.authenticator.waitForAuthentication(on: sfuAdapter)

                    /// With the ``SFUAdapter`` having a `connectionState` to
                    /// `.authenticating`, we store the instance on the ``WebRTCStateAdapter``.
                    await coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
                    /// From the ``JoinCallResponse`` we got from the authenticator, we extract
                    /// the name of the SFU we are currently connected, so we can use it later on
                    /// during `migration`.
                    context.currentSFU = response.credentials.server.edgeName

                    /// We are going to transition to the next stage ``.connected``. If that transition
                    /// fail for any reason, we will transition to ``.disconnected`` to allow for
                    /// reconnection.
                    transitionOrDisconnect(.connected(context))
                } catch {
                    /// In case of an error, we transition to ``.disconnected`` with the error
                    /// stored in the context, in order to allow for reconnection.
                    transitionDisconnectOrError(error)
                }
            }
        }
    }
}
