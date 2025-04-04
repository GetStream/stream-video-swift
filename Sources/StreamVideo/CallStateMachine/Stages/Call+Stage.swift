//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Call.StateMachine {
    /// Represents a stage in the call state machine.
    class Stage: StreamStateMachineStage, @unchecked Sendable {

        struct Context {
            struct JoinInput: ReflectiveStringConvertible {
                var create: Bool
                var callSettings: CallSettings?
                var options: CreateCallOptions?
                var ring: Bool
                var notify: Bool
                var deliverySubject: PassthroughSubject<JoinCallResponse, Error>

                var currentNumberOfRetries = 0
                var maxNumberOfRetries = 3
                var retryDelayRange: ClosedRange<TimeInterval> = 0.25...0.5
            }

            struct AcceptingInput {
                var deliverySubject: PassthroughSubject<AcceptCallResponse, Error>
            }

            struct RejectingInput {
                var reason: String?
                var deliverySubject: PassthroughSubject<RejectCallResponse, Error>
            }

            weak var call: Call?

            var joinInput: JoinInput? = nil
            var acceptingInput: AcceptingInput? = nil
            var rejectingInput: RejectingInput? = nil

            var joinResponse: JoinCallResponse? = nil
            var acceptResponse: AcceptCallResponse? = nil
            var rejectResponse: RejectCallResponse? = nil
        }

        /// Possible stage identifiers in the call state machine.
        enum ID: Hashable, CaseIterable {
            case idle
            case joining
            case joined
            case accepting
            case accepted
            case rejecting
            case rejected
            case error
        }

        /// The identifier for the current stage.
        let id: ID

        let container: String = "Call"

        /// The context for the current stage.
        var context: Context

        /// The transition closure for the stage.
        var transition: Transition?

        /// Creates a new stage with the given identifier and context.
        ///
        /// - Parameters:
        ///   - id: The identifier for the stage
        ///   - context: The context containing necessary state
        init(id: ID, context: Context) {
            self.id = id
            self.context = context
        }

        /// Called before transitioning away from this stage.
        func willTransitionAway() { /* No-op */ }

        /// Called after transitioning away from this stage.
        func didTransitionAway() { /* No-op */ }

        /// Handles state transitions to this stage.
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            nil // No-op
        }

        // MARK: - Helper transitions

        /// Transitions to error state or logs the error if transition fails.
        ///
        /// - Parameter error: The error that occurred
        func transitionErrorOrLog(_ error: Error) {
            do {
                try transition?(.error(.init(call: context.call), error: error))
            } catch {
                log.error(error)
            }
        }

        /// Transitions to the next stage or to error state if transition fails.
        ///
        /// - Parameter nextStage: The next stage to transition to
        func transitionOrError(_ nextStage: Stage) {
            do {
                try transition?(nextStage)
            } catch {
                transitionErrorOrLog(error)
            }
        }
    }
}
