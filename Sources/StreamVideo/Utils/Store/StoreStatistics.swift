//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class StoreStatistics<Namespace: StoreNamespace> {

    typealias Reporter = (Int, TimeInterval) -> Void

    private let processingQueue = UnfairQueue()
    private var actions: [String] = []
    private var cancellable: AnyCancellable?

    private var interval: TimeInterval = 0
    private var report: Reporter?

    func enable(interval: TimeInterval, reporter: Reporter) {
        self.interval = interval
        processingQueue.sync { actions = [] }
        cancellable?.cancel()
        cancellable = DefaultTimer
            .publish(every: interval)
            .sink { [weak self] _ in self?.flush() }
    }

    func disable() {
        cancellable?.cancel()
        cancellable = nil
    }

    func record(_ action: Namespace.Action) {
        processingQueue.sync { actions.append("\(action)") }
    }

    private func flush() {
        let snapshot = processingQueue.sync {
            let result = actions
            actions = []
            return result
        }

        guard !snapshot.isEmpty else {
            return
        }

        report?(snapshot.count, interval)
    }
}
