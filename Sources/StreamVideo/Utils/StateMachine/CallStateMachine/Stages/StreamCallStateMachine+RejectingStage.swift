//
//  StreamCallStateMachine+RejectingStage.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 21/5/24.
//

extension StreamCallStateMachine.Stage {

    static func rejecting(
        _ call: Call?,
        actionBlock: @escaping () async throws -> RejectCallResponse
    ) -> StreamCallStateMachine.Stage {
        RejectingStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    final class RejectingStage: StreamCallStateMachine.Stage {
        @Injected(\.callCache) private var callCache

        let actionBlock: () async throws -> RejectCallResponse

        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> RejectCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .rejecting, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                Task {
                    do {
                        let response = try await actionBlock()
                        if let call {
                            callCache.removeCall(
                                callType: call.callType,
                                callId: call.callId
                            )
                        }
                        try transition?(.rejected(call, response: response))
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

