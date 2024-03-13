//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnfairQueue {

    private let lock: os_unfair_lock_t

    init() {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit { lock.deallocate() }

    func sync<T>(_ block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try block()
    }
}
