//
//  WebRTCCoordinator+Connected.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func connected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class ConnectedStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .connected, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                do {
                    try transition?(
                        .joining(
                            context
                        )
                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}

