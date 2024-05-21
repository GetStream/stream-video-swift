//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func joining(
        _ call: Call?,
        actionBlock: @escaping () async throws -> JoinCallResponse
    ) -> StreamCallStateMachine.Stage {
        JoiningStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    final class JoiningStage: StreamCallStateMachine.Stage {
        let actionBlock: () async throws -> JoinCallResponse

        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> JoinCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .joining, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle, .accepted:
                Task {
                    do {
                        let response = try await actionBlock()
                        try transition?(.joined(call, response: response))
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
