//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a rejoining stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the rejoining stage.
    /// - Returns: A `RejoiningStage` instance representing the rejoining state
    ///   of the WebRTC coordinator.
    static func rejoining(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        RejoiningStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the rejoining stage in the WebRTC coordinator state machine.
    final class RejoiningStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `RejoiningStage`.
        /// - Parameter context: The context for the rejoining stage.
        init(
            _ context: Context
        ) {
            super.init(id: .rejoining, context: context)
        }

        /// Performs the transition from a previous stage to this rejoining
        /// stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `RejoiningStage` instance if the transition is
        ///   valid, otherwise `nil`.
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

        /// Executes the rejoining process.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                do {
                    guard
                        let self,
                        let coordinator = context.coordinator
                    else {
                        throw ClientError(
                            "WebRCTCoordinator instance not available."
                        )
                    }

                    try Task.checkCancellation()

                    if
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter {
                        if case .connected = sfuAdapter.connectionState {
                            await sfuAdapter.sendLeaveRequest(
                                for: coordinator.stateAdapter.sessionID
                            )
                        }
                        await sfuAdapter.disconnect()
                    }

                    try Task.checkCancellation()

                    context.isRejoiningFromSessionID = await coordinator
                        .stateAdapter
                        .sessionID

                    try Task.checkCancellation()

                    context.previousSessionPublisher = await context
                        .coordinator?
                        .stateAdapter
                        .publisher

                    try Task.checkCancellation()

                    context.previousSessionSubscriber = await context
                        .coordinator?
                        .stateAdapter
                        .subscriber

                    try Task.checkCancellation()

                    context.sfuEventObserver?.stopObserving()

                    try Task.checkCancellation()

                    await coordinator
                        .stateAdapter
                        .cleanUpForReconnection()

                    try Task.checkCancellation()

                    transitionOrDisconnect(
                        .connecting(
                            context,
                            create: false,
                            options: nil,
                            ring: false,
                            notify: false
                        )
                    )
                } catch {
                    self?.transitionDisconnectOrError(error)
                }
            }
        }
    }
}
