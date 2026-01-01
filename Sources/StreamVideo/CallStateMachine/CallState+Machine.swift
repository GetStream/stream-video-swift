//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A state machine that manages the states of a stream call.
extension Call {
    final class StateMachine {
        /// The underlying state machine that handles state transitions.
        private let stateMachine: StreamStateMachine<Stage>

        /// The current stage of the state machine.
        var currentStage: Stage { stateMachine.currentStage }

        /// A publisher that emits the current stage of the state machine.
        var publisher: AnyPublisher<Stage, Never> { stateMachine.publisher.eraseToAnyPublisher() }

        /// Initializes the state machine with the idle stage for a given call.
        ///
        /// - Parameter call: The call to be managed by the state machine.
        init(_ call: Call) {
            stateMachine = .init(initialStage: .idle(.init(call: call)))
        }

        /// Transitions the state machine to the given next stage.
        ///
        /// - Parameter nextStage: The next stage to transition to.
        /// - Throws: An error if the transition is invalid.
        func transition(
            _ nextStage: Stage,
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            stateMachine.transition(
                to: nextStage,
                file: file,
                function: function,
                line: line
            )
        }

        func withLock<T>(
            _ operation: (Stage, (Stage) -> Void) -> T
        ) -> T {
            stateMachine.withLock(operation)
        }
    }
}
