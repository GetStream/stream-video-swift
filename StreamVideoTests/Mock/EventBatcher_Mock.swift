//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import protocol StreamVideo.Timer

final class EventBatcher_Mock: EventBatcher, @unchecked Sendable {
    var currentBatch: [WrappedEvent] = []

    let handler: @Sendable (_ batch: [WrappedEvent], _ completion: @escaping @Sendable () -> Void) -> Void

    init(
        period: TimeInterval = 0,
        timerType: Timer.Type = DefaultTimer.self,
        handler: @escaping @Sendable (_ batch: [WrappedEvent], _ completion: @escaping @Sendable () -> Void) -> Void
    ) {
        self.handler = handler
    }

    lazy var mock_append = MockFunc.mock(for: append)

    func append(_ event: WrappedEvent) {
        mock_append.call(with: (event))

        handler([event]) {}
    }

    lazy var mock_processImmediately = MockFunc.mock(for: processImmediately)

    func processImmediately(completion: @escaping () -> Void) {
        mock_processImmediately.call(with: (completion))
    }
}
