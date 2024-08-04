//
//  WebRTCClient+Idle.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 1/8/24.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func idle(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        IdleStage(context)
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class IdleStage: WebRTCClient.StateMachine.Stage {

        convenience init(_ context: Context) {
            self.init(id: .idle, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            self
        }
    }
}

