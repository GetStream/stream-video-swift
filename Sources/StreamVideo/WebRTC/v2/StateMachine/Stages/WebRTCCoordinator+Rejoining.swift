//
//  WebRTCCoordinator+Rejoining.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
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

                    if
                        let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
                    {
                        if case .connected = sfuAdapter.connectionState {
                            await sfuAdapter.sendLeaveRequest(
                                for: coordinator.stateAdapter.sessionID
                            )
                        }
                        await sfuAdapter.disconnect()
                    }

                    context.isRejoiningFromSessionID = await coordinator
                        .stateAdapter
                        .sessionID

                    await coordinator
                        .stateAdapter
                        .cleanUpForReconnection()

                    context.previousSessionPublisher = await context
                        .coordinator?
                        .stateAdapter
                        .publisher

                    context.previousSessionSubscriber = await context
                        .coordinator?
                        .stateAdapter
                        .subscriber

                    try transition?(
                        .connecting(
                            context
                        )
                    )
                } catch (let blockError) {
                    do {
                        context.disconnectionSource = .serverInitiated(
                            error: ClientError(blockError.localizedDescription)
                        )
                        try transition?(
                            .disconnected(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(blockError)
                    }
                }
            }
        }
    }
}

