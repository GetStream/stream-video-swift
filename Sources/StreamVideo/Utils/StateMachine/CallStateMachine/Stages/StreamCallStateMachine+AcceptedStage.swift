//
//  StreamCallStateMachine+AcceptedStage.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 21/5/24.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func accepted(
        _ call: Call?,
        response: AcceptCallResponse
    ) -> StreamCallStateMachine.Stage {
        AcceptedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    final class AcceptedStage: StreamCallStateMachine.Stage {
        let response: AcceptCallResponse

        init(
            _ call: Call?,
            response: AcceptCallResponse
        ) {
            self.response = response
            super.init(id: .accepted, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .accepting:
                return self
            default:
                return nil
            }
        }
    }
}
