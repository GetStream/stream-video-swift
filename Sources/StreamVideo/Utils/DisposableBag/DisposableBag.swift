//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class DisposableBag: Sequence, @unchecked Sendable {

    private let queue = UnfairQueue()
    private var storage: [String: AnyCancellable] = [:]

    public init() {}

    public func insert(
        _ cancellable: AnyCancellable,
        with key: String = UUID().uuidString
    ) {
        queue.sync {
            storage[key]?.cancel()
            storage[key] = cancellable
        }
    }

    public func remove(_ key: String) {
        queue.sync {
            storage[key]?.cancel()
            storage[key] = nil
        }
    }

    public func removeAll() {
        queue.sync {
            storage.values.forEach { $0.cancel() }
            storage = [:]
        }
    }

    // Sequence conformance
    public func makeIterator() -> Set<AnyCancellable>.Iterator {
        queue.sync {
            Set(storage.values).makeIterator()
        }
    }
}

extension AnyCancellable {
    public func store(in disposableBag: DisposableBag) { disposableBag.insert(self) }
}

extension Task {
    
    func eraseToAnyCancellable() -> AnyCancellable { .init(cancel) }

    public func store(
        in disposableBag: DisposableBag,
        key: String = UUID().uuidString
    ) { disposableBag.insert(.init(cancel), with: key) }
}
