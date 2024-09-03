//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A state machine that manages transitions between different stages.
///
/// - Parameter StageType: The type of the stages managed by the state machine, conforming to `StreamStateMachineStage`.
public final class StreamStateMachine<StageType: StreamStateMachineStage> {
    /// The current stage of the state machine.
    public var currentStage: StageType { publisher.value }
    /// A publisher that broadcasts the current stage.
    public let publisher: CurrentValueSubject<StageType, Never>

    /// A queue to ensure thread-safe operations.
    private let queue: UnfairQueue = .init()
    private let logSubsystem: LogSubsystem

    /// Initializes the state machine with an initial stage.
    ///
    /// - Parameter initialStage: The initial stage of the state machine.
    public init(initialStage: StageType, logSubsystem: LogSubsystem = .other) {
        self.logSubsystem = logSubsystem
        publisher = .init(initialStage)
    }

    /// Transitions to a new stage.
    ///
    /// - Parameter nextStage: The next stage to transition to.
    /// - Throws: An error if the transition is not allowed.
    public func transition(to nextStage: StageType) throws {
        try queue.sync {
            var nextStage = nextStage
            nextStage.transition = { [weak self] in try self?.transition(to: $0) }

            let transitioningFromStage = currentStage
            transitioningFromStage.willTransitionAway()
            
            guard
                let newStage = nextStage.transition(from: currentStage),
                newStage.id.hashValue != currentStage.id.hashValue
            else {
                throw ClientError.InvalidStateMachineTransition(from: currentStage, to: nextStage)
            }

            transitioningFromStage.didTransitionAway()

            log.debug(
                "Transition \(String(describing: currentStage.description)) → \(newStage.description)",
                subsystems: logSubsystem
            )
            publisher.send(nextStage)
        }
    }
}

extension ClientError {
    /// An error representing an invalid state machine transition.
    struct InvalidStateMachineTransition: Error, CustomStringConvertible {
        /// The error message.
        var message: String
        /// A textual representation of the error, which is the message.
        var description: String { message }

        /// Initializes the error with details about the invalid transition.
        ///
        /// - Parameters:
        ///   - from: The stage from which the transition was attempted.
        ///   - to: The stage to which the transition was attempted.
        init(from: any StreamStateMachineStage, to: any StreamStateMachineStage) {
            message = "Cannot transition from \(String(describing: from.description)) → \(to.description)"
        }
    }
}
