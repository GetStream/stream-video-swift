//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A cache for managing `Call` instances, ensuring thread-safe operations.
final class CallCache {
    /// A queue for synchronizing access to the cache.
    private let queue = UnfairQueue()
    /// The underlying storage for cached calls.
    private var storage: [String: Call] = [:]

    /// Dequeues a `Call` from the cache or creates a new one using the provided factory.
    ///
    /// - Parameters:
    ///   - cId: The ``cId`` of the call.
    ///   - factory: A closure that creates a new `Call` instance if none exists in the cache.
    /// - Returns: A `Call` instance, either from the cache or newly created.
    func call(
        for cId: String,
        factory: () -> Call
    ) -> Call {
        queue.sync {
            if let cached = storage[cId] {
                return cached
            } else {
                let call = factory()
                storage[cId] = call
                return call
            }
        }
    }

    /// Remove a `Call` from the cache.
    ///
    /// - Parameters:
    ///   - cId: The ``cID`` of the call.
    func remove(for cId: String) {
        queue.sync {
            storage[cId] = nil
        }
    }

    func removeAll() {
        queue.sync {
            storage.removeAll()
        }
    }
}

extension CallCache: InjectionKey {
    static var currentValue: CallCache = .init()
}

extension InjectedValues {
    var callCache: CallCache {
        get { Self[CallCache.self] }
        set { Self[CallCache.self] = newValue }
    }
}
