//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A synchronization utility implementing a recursive locking mechanism.
///
/// This class provides a way to synchronize access to resources using `NSRecursiveLock`,
/// which allows the same thread to acquire the lock multiple times without deadlocking.
/// This is useful in recursive or reentrant code where multiple methods that may call each other
/// need to access a shared resource.
///
/// `NSRecursiveLock` is an Objective-C-based recursive lock that provides thread safety in situations
/// where the same thread needs to acquire the lock more than once. Unlike `os_unfair_lock`, which is non-recursive
/// and prioritizes performance, `NSRecursiveLock` ensures that the same thread can enter critical sections
/// repeatedly, avoiding deadlock in reentrant code scenarios.
///
/// While `NSRecursiveLock` has more overhead than `os_unfair_lock`, it is ideal for more complex code flows
/// where reentrancy or recursive method calls require safe locking. This makes it a better fit than
/// `os_unfair_lock` when you need the flexibility to enter the lock multiple times on the same thread.
public final class RecursiveQueue: LockQueuing, @unchecked Sendable {

    /// The recursive lock instance.
    private let lock = NSRecursiveLock()

    /// Initializes a new instance of `RecursiveQueue`.
    public init() {}

    /// Executes a block with mutual exclusion via a recursive lock.
    ///
    /// - Parameter block: The block of code to execute safely under the lock.
    /// - Returns: The value returned by the block, if any.
    /// - Throws: Rethrows any errors thrown by the block.
    public func sync<T>(_ block: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try block()
    }
}
