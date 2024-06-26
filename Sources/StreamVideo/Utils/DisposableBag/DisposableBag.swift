//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class DisposableBag: Sequence {

    private let queue = UnfairQueue()
    private var storage: Set<AnyCancellable> = []

    public init() {}

    public func insert(_ cancellable: AnyCancellable) {
        queue.sync {
            _ = storage.insert(cancellable)
        }
    }

    public func removeAll() {
        queue.sync {
            storage.forEach { $0.cancel() }
            storage = []
        }
    }

    // Sequence conformance
    public func makeIterator() -> Set<AnyCancellable>.Iterator {
        queue.sync {
            storage.makeIterator()
        }
    }
}

extension AnyCancellable {
    public func store(in disposableBag: DisposableBag) { disposableBag.insert(self) }
}
