//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A state machine that manages the states of a stream call.
final class StreamCallStateMachine {
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
        stateMachine = .init(initialStage: .idle(call))
    }

    /// Transitions the state machine to the given next stage.
    ///
    /// - Parameter nextStage: The next stage to transition to.
    /// - Throws: An error if the transition is invalid.
    func transition(_ nextStage: Stage) {
        stateMachine.transition(to: nextStage)
    }

    /// Waits for the next stage of the specified type after optionally skipping initial stages.
    ///
    /// - Parameters:
    ///   - stageType: The expected type of the next stage.
    ///   - dropFirst: The number of initial stages to skip. Defaults to 0.
    /// - Returns: The next stage of the specified type.
    /// - Throws: An error if the next stage is not of the expected type or if the state machine transitions to an error stage.
    func nextStageShouldBe<S: Stage>(
        _ stageType: S.Type,
        dropFirst: Int = 0
    ) async throws -> S {
        let stage = try await stateMachine.publisher.nextValue(dropFirst: dropFirst)
        guard let expected = stage as? S else {
            if let errorState = stage as? StreamCallStateMachine.Stage.ErrorStage {
                throw errorState.error
            } else {
                throw ClientError
                    .Unexpected(
                        "\(type(of: self)) was expecting next state (after dropping \(dropFirst)) to be \(S.self) but it is \(type(of: stage))."
                    )
            }
        }
        return expected
    }
}
