//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

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

        func remove(_ key: String) {
            queue.sync {
                storage[key]?.cancel()
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
        storage.remove(key)
    }

    public func removeAll() {
        storage.removeAll()
    }

    public var isEmpty: Bool { storage.isEmpty }
}

extension AnyCancellable {
    public func store(in disposableBag: DisposableBag?) { disposableBag?.insert(self) }
}

extension Task {
    
    func eraseToAnyCancellable() -> AnyCancellable { .init(cancel) }

    public func store(
        in disposableBag: DisposableBag,
        key: String = UUID().uuidString
    ) { disposableBag.insert(.init(cancel), with: key) }
}

extension AnyCancellable: @unchecked Sendable {}
