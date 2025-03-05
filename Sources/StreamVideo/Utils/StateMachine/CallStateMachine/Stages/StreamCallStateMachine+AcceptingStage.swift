//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

extension StreamCallStateMachine.Stage {

    /// Creates an accepting stage for the provided call with the specified action block.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - actionBlock: An asynchronous action block returning an `AcceptCallResponse`.
    /// - Returns: An `AcceptingStage` instance.
    static func accepting(
        _ call: Call?,
        actionBlock: @escaping () async throws -> AcceptCallResponse
    ) -> StreamCallStateMachine.Stage {
        AcceptingStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the accepting stage in the `StreamCallStateMachine`.
    final class AcceptingStage: StreamCallStateMachine.Stage, @unchecked Sendable {
        let actionBlock: () async throws -> AcceptCallResponse

        /// Initializes a new accepting stage with the provided call and action block.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - actionBlock: An asynchronous action block returning an `AcceptCallResponse`.
        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> AcceptCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .accepting, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `AcceptingStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `IdleStage`
        ///   - To: `AcceptedStage`
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
