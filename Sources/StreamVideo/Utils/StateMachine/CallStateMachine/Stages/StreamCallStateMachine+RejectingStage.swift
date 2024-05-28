//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

extension StreamCallStateMachine.Stage {

    /// Creates a rejecting stage for the provided call with the specified action block.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - actionBlock: The async action block to be executed.
    /// - Returns: A `RejectingStage` instance.
    static func rejecting(
        _ call: Call?,
        actionBlock: @escaping () async throws -> RejectCallResponse
    ) -> StreamCallStateMachine.Stage {
        RejectingStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the rejecting stage in the `StreamCallStateMachine`.
    final class RejectingStage: StreamCallStateMachine.Stage {
        @Injected(\.callCache) private var callCache

        let actionBlock: () async throws -> RejectCallResponse

        /// Initializes a new rejecting stage with the provided call and action block.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - actionBlock: The async action block to be executed.
        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> RejectCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .rejecting, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `RejectingStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `IdleStage`
        ///   - To: `RejectedStage`
        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                Task {
                    do {
                        let response = try await actionBlock()
                        if let cId = call?.cId {
                            callCache.remove(for: cId)
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
