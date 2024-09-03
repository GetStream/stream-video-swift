//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class DisposableBag: @unchecked Sendable {

    private actor Storage {
        private var storage: [String: AnyCancellable] = [:]

        deinit {
            storage.values.forEach { $0.cancel() }
        }

        func insert(
            _ cancellable: AnyCancellable,
            with key: String = UUID().uuidString
        ) {
            storage[key]?.cancel()
            storage[key] = cancellable
        }

        public func remove(_ key: String) {
            storage[key]?.cancel()
            storage[key] = nil
        }

        public func removeAll() {
            storage.values.forEach { $0.cancel() }
            storage = [:]
        }
    }

    private let storage: Storage = .init()

    public init() {}

    public func insert(
        _ cancellable: AnyCancellable,
        with key: String = UUID().uuidString
    ) {
        Task {
            await storage.insert(cancellable, with: key)
        }
    }

    public func remove(_ key: String) {
        Task {
            await storage.remove(key)
        }
    }

    public func removeAll() {
        Task {
            await storage.removeAll()
        }
    }
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
