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

    func transition(_ nextStage: Stage) {
        stateMachine.transition(to: nextStage)
    }
}
