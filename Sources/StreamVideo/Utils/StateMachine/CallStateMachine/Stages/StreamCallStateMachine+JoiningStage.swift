//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    /// Creates a joining stage for the provided call with the specified action block.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - actionBlock: The async action block to execute during the transition.
    /// - Returns: A `JoiningStage` instance.
    static func joining(
        _ call: Call?,
        actionBlock: @escaping () async throws -> JoinCallResponse
    ) -> StreamCallStateMachine.Stage {
        JoiningStage(call, actionBlock: actionBlock)
    }
}

extension StreamCallStateMachine.Stage {

    /// A class representing the joining stage in the `StreamCallStateMachine`.
    final class JoiningStage: StreamCallStateMachine.Stage {
        let actionBlock: () async throws -> JoinCallResponse

        /// Initializes a new joining stage with the provided call and action block.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - actionBlock: The async action block to execute during the transition.
        init(
            _ call: Call?,
            actionBlock: @escaping () async throws -> JoinCallResponse
        ) {
            self.actionBlock = actionBlock
            super.init(id: .joining, call: call)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `JoiningStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transitions:
        ///   - From: `IdleStage`, `AcceptedStage`
        ///   - To: `JoinedStage`, `ErrorStage`
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
