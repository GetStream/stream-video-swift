//
//  StreamCallStateMachine+AcceptingStage.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 21/5/24.
//

extension StreamCallStateMachine.Stage {

    static func accepting(
        _ call: Call?,
        actionBlock: @escaping () async throws -> AcceptCallResponse
    ) -> StreamCallStateMachine.Stage {
        AcceptingStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    final class AcceptingStage: StreamCallStateMachine.Stage {
        let actionBlock: () async throws -> AcceptCallResponse

        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> AcceptCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .accepting, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                Task {
                    do {
                        let response = try await actionBlock()
                        try transition?(.accepted(call, response: response))
                    } catch {
                        do {
                            try transition?(.error(call, error: error))
                        } catch {
                            log.error(error)
                        }
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
