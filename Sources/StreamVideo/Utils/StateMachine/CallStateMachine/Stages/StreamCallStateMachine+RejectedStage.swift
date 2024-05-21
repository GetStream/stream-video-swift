//
//  StreamCallStateMachine+RejectedStage.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 21/5/24.
//

extension StreamCallStateMachine.Stage {

    static func rejected(
        _ call: Call?,
        response: RejectCallResponse
    ) -> StreamCallStateMachine.Stage {
        RejectedStage(
            call,
            response: response
        )
    }
}

extension StreamCallStateMachine.Stage {

    final class RejectedStage: StreamCallStateMachine.Stage {
        let response: RejectCallResponse

        init(
            _ call: Call?,
            response: RejectCallResponse
        ) {
            self.response = response
            super.init(id: .rejected, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .rejecting:
                return self
            default:
                return nil
            }
        }
    }
}

