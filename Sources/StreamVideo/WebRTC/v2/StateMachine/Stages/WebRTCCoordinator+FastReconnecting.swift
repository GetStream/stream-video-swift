//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a fast reconnecting stage for the WebRTC coordinator
    /// state machine.
    /// - Parameter context: The context for the fast reconnecting stage.
    /// - Returns: A `FastReconnectingStage` instance representing the fast
    ///   reconnecting state of the WebRTC coordinator.
    static func fastReconnecting(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        FastReconnectingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the fast reconnecting stage in the WebRTC coordinator state
    /// machine.
    final class FastReconnectingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `FastReconnectingStage`.
        /// - Parameter context: The context for the fast reconnecting stage.
        init(
            _ context: Context
        ) {
            super.init(id: .fastReconnecting, context: context)
        }

        /// Performs the transition from a previous stage to this fast
        /// reconnecting stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `FastReconnectingStage` instance if the transition
        ///   is valid, otherwise `nil`.
        /// - Note: Valid transition from: `.disconnected`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .disconnected:
                execute()
                return self
            default:
                return nil
            }
        }

        /// Executes the fast reconnecting process.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let coordinator = context.coordinator,
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    try Task.checkCancellation()

                    log.debug("Refreshing webSocket", subsystems: .webRTC)
                    sfuAdapter.refresh(
                        webSocketConfiguration: .init(
                            url: sfuAdapter.connectURL,
                            eventNotificationCenter: .init()
                        )
                    )

                    try Task.checkCancellation()

                    log.debug(
                        "Waiting for webSocket state to change to authenticating",
                        subsystems: .webRTC
                    )

                    try await context.authenticator.waitForAuthentication(on: sfuAdapter)

                    transitionOrDisconnect(.fastReconnected(context))
                } catch {
                    context.reconnectionStrategy = context.nextReconnectionStrategy()
                    transitionDisconnectOrError(error)
                }
            }
        }
    }
}
