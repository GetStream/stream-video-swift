//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Combine
import Foundation

public final class DisposableBag: @unchecked Sendable {

    private final class Storage {
        private var storage: [String: AnyCancellable] = [:]
        private let queue = UnfairQueue()

        deinit {
            storage.values.forEach { $0.cancel() }
        }

        func insert(
            _ cancellable: AnyCancellable,
            with key: String = UUID().uuidString
        ) {
            queue.sync {
                storage[key]?.cancel()
                storage[key] = cancellable
            }
        }

        func remove(_ key: String, cancel: Bool) {
            queue.sync {
                if cancel {
                    storage[key]?.cancel()
                }
                storage[key] = nil
            }
        }

        func removeAll() {
            queue.sync {
                storage.values.forEach { $0.cancel() }
                storage = [:]
            }
        }

        var isEmpty: Bool { queue.sync { storage.isEmpty } }
    }

    private let storage: Storage = .init()

    public init() {}

    public func insert(
        _ cancellable: AnyCancellable,
        with key: String = UUID().uuidString
    ) {
        storage.insert(cancellable, with: key)
    }

    public func remove(_ key: String) {
        storage.remove(key, cancel: true)
    }

    public func removeAll() {
        storage.removeAll()
    }

    public var isEmpty: Bool { storage.isEmpty }

    public func completed(_ key: String) {
        storage.remove(key, cancel: false)
    }
}

extension AnyCancellable {
    public func store(
        in disposableBag: DisposableBag?,
        key: String = UUID().uuidString
    ) { disposableBag?.insert(self, with: key) }
}

extension Task {
    func eraseToAnyCancellable() -> AnyCancellable { .init(cancel) }
}
