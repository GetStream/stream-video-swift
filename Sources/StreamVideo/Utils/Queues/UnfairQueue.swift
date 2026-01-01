//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A synchronization utility implementing an unfair locking mechanism.
///
/// This class provides a way to synchronize access to resources using `os_unfair_lock`,
/// which offers a fast and efficient locking mechanism but can lead to priority inversion.
///
/// `os_unfair_lock` stands out for its direct approach to synchronization, providing high-performance,
/// low-level locking that is especially beneficial when you need to protect small sections of code or data
/// swiftly. It operates with minimal overhead, avoiding the complexities of context switching or thread management,
/// which is a stark contrast to DispatchQueue.
///
/// When using a DispatchQueue, there is inherent overhead because it schedules tasks and potentially shifts
/// execution onto a specific thread, depending on the queue's configuration (main or background). This can
/// introduce delays as tasks are queued and executed according to the system's scheduling algorithms,
/// which might not be as immediate as the direct locking mechanism provided by `os_unfair_lock`.
///
/// The lock's efficiency and speed are particularly advantageous in high-performance contexts where the
/// additional overhead of dispatching tasks and managing thread execution in a DispatchQueue could result
/// in unnecessary latency, making `os_unfair_lock` the superior choice for scenarios where rapid, lightweight
/// synchronization is paramount.
public final class UnfairQueue: LockQueuing, @unchecked Sendable {

    /// The unfair lock variable, managed as an unsafe mutable pointer to `os_unfair_lock`.
    private let lock: os_unfair_lock_t

    /// Initializes a new instance of `UnfairQueue`.
    ///
    /// It allocates memory for an `os_unfair_lock` and initializes it.
    public init() {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    /// Deinitializes the instance, deallocating the unfair lock.
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    /// Executes a block of code, ensuring mutual exclusion via an unfair lock.
    ///
    /// The method locks before the block executes and unlocks after the block completes.
    /// It's designed to be exception-safe, unlocking even if an error is thrown within the block.
    ///
    /// - Parameter block: The block of code to execute safely under the lock.
    /// - Returns: The value returned by the block, if any.
    /// - Throws: Rethrows any errors that are thrown by the block.
    public func sync<T>(_ block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try block()
    }
}
