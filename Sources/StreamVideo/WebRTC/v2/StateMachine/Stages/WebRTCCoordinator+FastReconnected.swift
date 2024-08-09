//
//  WebRTCCoordinator+FastReconnected.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func fastReconnected(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        FastReconnectedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class FastReconnectedStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .fastReconnected, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .fastReconnecting:
                Task {
                    do {
                        try transition?(
                            .joining(
                                context
                            )
                        )
                    } catch {
                        log.error(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}

