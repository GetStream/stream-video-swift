//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore

// All mutable ring state is protected by the queue.
final class Queue<T: Sendable>: @unchecked Sendable {
    private let queue = UnfairQueue()
    private var storage: [T?]
    private var nextIndex = 0
    private var count = 0

    var elements: [T] {
        queue.sync {
            (0..<count).compactMap {
                storage[(nextIndex - 1 - $0 + storage.count) % storage.count]
            }
        }
    }

    init(maxCount: Int) {
        precondition(maxCount >= 0)
        storage = Array(repeating: nil, count: maxCount)
    }

    func insert(_ element: T) {
        queue.sync {
            guard !storage.isEmpty else { return }
            storage[nextIndex] = element
            nextIndex = (nextIndex + 1) % storage.count
            count = min(count + 1, storage.count)
        }
    }
}
