//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a leaving stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the leaving stage.
    /// - Returns: A `LeavingStage` instance representing the leaving state of
    ///   the WebRTC coordinator.
    static func leaving(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        LeavingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the leaving stage in the WebRTC coordinator state machine.
    final class LeavingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `LeavingStage`.
        /// - Parameter context: The context for the leaving stage.
        init(
            _ context: Context
        ) {
            super.init(id: .leaving, context: context)
        }

        /// Performs the transition from a previous stage to this leaving stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `LeavingStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: `.joined`, `.disconnected`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined, .disconnected, .connecting, .connected:
                execute()
                return self
            default:
                return nil
            }
        }

        /// Executes the leaving process.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    guard
                        let coordinator = context.coordinator
                    else {
                        throw ClientError("WebRCTAdapter instance not available.")
                    }

                    try Task.checkCancellation()

                    if let sfuAdapter = await coordinator.stateAdapter.sfuAdapter {
                        if case .connected = sfuAdapter.connectionState {
                            await sfuAdapter.sendLeaveRequest(
                                for: coordinator.stateAdapter.sessionID
                            )
                        }
                        await sfuAdapter.disconnect()
                    }

                    try transition?(.cleanUp(context))
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
