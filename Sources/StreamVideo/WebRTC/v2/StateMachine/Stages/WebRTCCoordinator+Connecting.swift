//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    /// - Important: When transitioning from `.rejoining` values for ``ring``,
    /// ``notify`` & ``options`` are nullified as are not relevant to the `rejoining` flow.
    static func connecting(
        _ context: Context,
        create: Bool,
        options: CreateCallOptions?,
        ring: Bool,
        notify: Bool
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectingStage(
            context,
            create: create,
            options: options,
            ring: ring,
            notify: notify
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the connecting stage in the WebRTC coordinator state machine.
    final class ConnectingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        let create: Bool
        let options: CreateCallOptions?
        /// Indicates whether to ring the other participants.
        let ring: Bool
        let notify: Bool

        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `ConnectingStage`.
        /// - Parameters:
        ///   - context: The context for the connecting stage.
        ///   - ring: A Boolean indicating whether to ring other participants.
        init(
            _ context: Context,
            create: Bool,
            options: CreateCallOptions?,
            ring: Bool,
            notify: Bool
        ) {
            self.create = create
            self.options = options
            self.ring = ring
            self.notify = notify
            super.init(id: .connecting, context: context)
        }

        /// Performs the transition from a previous stage to this connecting
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `ConnectingStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Important: When transitioning from `.rejoining` values for ``ring``,
        /// ``notify`` & ``options`` are nullified as are not relevant to the `rejoining` flow.
        /// - Note: Valid transition from: `.idle`,  `.rejoining`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute(
                    create: create,
                    ring: ring,
                    notify: notify,
                    options: options,
                    updateSession: false,
                    onErrorDisconnect: false
                )
                return self
            case .rejoining:
                if ring || notify || options != nil {
                    log.assert(ring == false, "Ring cannot be true when rejoining.")
                    log.assert(notify == false, "Notify cannot be true when rejoining.")
                    log.assert(options == nil, "CreateCallOptions cannot be non-nil when rejoining.")
                }
                execute(
                    create: false,
                    ring: false,
                    notify: false,
                    options: nil,
                    updateSession: true,
                    onErrorDisconnect: true
                )
                return self
            default:
                return nil
            }
        }

        /// Executes the call connecting process.
        /// - Parameters:
        ///   - create: A Boolean indicating whether to create a new session.
        ///   - ring: A Boolean indicating whether to ring other participants.
        ///   - notify: A Boolean indicating whether to notify other participants.
        ///   - options: A `CreateCallOptions` instance to provide additional informations when
        ///   creating a call.
        ///   - updateSession: A Boolean indicating whether to update the
        ///     existing session.
        private func execute(
            create: Bool,
            ring: Bool,
            notify: Bool,
            options: CreateCallOptions?,
            updateSession: Bool,
            onErrorDisconnect: Bool
        ) {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let coordinator = context.coordinator
                    else {
                        throw ClientError("WebRTCCoordinator instance not available in stage id:\(id).")
                    }

                    try Task.checkCancellation()

                    if updateSession {
                        /// By refreshing the session, we are asking the stateAdapter to update
                        /// the sessionId to a new one.
                        await coordinator.stateAdapter.refreshSession()
                    }

                    try Task.checkCancellation()

                    /// The authenticator will fetch a ``JoinCallResponse`` and will use it to
                    /// create an ``SFUAdapter`` instance that we can later use in our flow.
                    let (sfuAdapter, response) = try await context
                        .authenticator
                        .authenticate(
                            coordinator: coordinator,
                            currentSFU: nil,
                            create: create,
                            ring: ring,
                            notify: notify,
                            options: options
                        )

                    try Task.checkCancellation()

                    /// We provide the ``SFUAdapter`` to the authenticator which will ensure
                    /// that we will continue only when the WS `connectionState` on the
                    /// ``SFUAdapter`` has changed to `.authenticating`.
                    try await context.authenticator.waitForAuthentication(on: sfuAdapter)

                    try Task.checkCancellation()

                    /// With the ``SFUAdapter`` having a `connectionState` to
                    /// `.authenticating`, we store the instance on the ``WebRTCStateAdapter``.
                    await coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
                    /// From the ``JoinCallResponse`` we got from the authenticator, we extract
                    /// the name of the SFU we are currently connected, so we can use it later on
                    /// during `migration`.
                    context.currentSFU = response.credentials.server.edgeName

                    try Task.checkCancellation()

                    /// We are going to transition to the next stage ``.connected``. If that transition
                    /// fail for any reason, we will transition to ``.disconnected`` to allow for
                    /// reconnection.
                    transitionOrDisconnect(.connected(context))
                } catch {
                    if onErrorDisconnect {
                        /// In case of an error, we transition to ``.disconnected`` with the error
                        /// stored in the context, in order to allow for reconnection.
                        transitionDisconnectOrError(error)
                    } else {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }
    }
}
