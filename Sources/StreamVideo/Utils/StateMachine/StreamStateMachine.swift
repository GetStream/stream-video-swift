//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class StreamStateMachine<StageType: StateMachineStage> {
    public var currentStage: StageType { publisher.value }
    public let publisher: CurrentValueSubject<StageType, Never>

    private let queue: UnfairQueue = .init()

    public init(initialStage: StageType) {
        publisher = .init(initialStage)
    }

    public func transition(to nextStage: StageType) {
        queue.sync {
            var nextStage = nextStage
            nextStage.transition = { [weak self] in self?.transition(to: $0) }
            guard
                let newStage = nextStage.transition(from: currentStage),
                newStage.id.hashValue != currentStage.id.hashValue
            else {
                log.debug("Cannot transition from \(String(describing: currentStage.description)) → \(nextStage.description)")
                return
            }

            log.debug("Transition \(String(describing: currentStage.description)) → \(newStage.description)")
            publisher.send(nextStage)
        }
    }
}
