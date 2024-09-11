//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func rejoining(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        RejoiningStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class RejoiningStage: WebRTCCoordinator.StateMachine.Stage {

        private let disposableBag = DisposableBag()

        init(
            _ context: Context
        ) {
            super.init(id: .rejoining, context: context)
        }

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

        private func execute() {
            Task {
                do {
                    guard let coordinator = context.coordinator else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
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

                    await coordinator
                        .stateAdapter
                        .cleanUpForReconnection()

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

                    try transition?(
                        .connecting(
                            context,
                            ring: false
                        )
                    )
                } catch {
                    if error is CancellationError {
                        /* No-op */
                    } else {
                        transitionDisconnectOrError(error)
                    }
                }
            }
            .store(in: disposableBag)
        }
    }
}
