//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class StreamCallStateMachine {
    private let stateMachine: StreamStateMachine<Stage>

    var currentStage: Stage { stateMachine.currentStage }
    var publisher: AnyPublisher<Stage, Never> { stateMachine.publisher.eraseToAnyPublisher() }

    init(_ call: Call) {
        stateMachine = .init(initialStage: .idle(call))
    }

    func transition(_ nextStage: Stage) throws {
        try stateMachine.transition(to: nextStage)
    }

    func nextStageShouldBe<S: Stage>(
        _ stageType: S.Type,
        dropFirst: Int = 0
    ) async throws -> S {
        let stage = try await stateMachine.publisher.nextValue(dropFirst: 1)
        guard let expected = stage as? S else {
            if let errorState = stage as? StreamCallStateMachine.Stage.ErrorStage {
                throw errorState.error
            } else {
                throw ClientError.InvalidState("\(type(of: self)) was expecting next state (after dropping \(dropFirst)) to be \(S.self) but it is \(type(of: stage))" )
            }
        }
        return expected
    }
}

extension ClientError {
    struct InvalidState: Error, CustomStringConvertible {

        init(_ message: String) { self.message = message }

        var message: String
        var description: String { message }
    }
}
