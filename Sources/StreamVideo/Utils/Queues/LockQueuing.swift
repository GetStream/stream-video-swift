//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol defining a lock-based synchronization interface.
///
/// Types conforming to `LockQueuing` provide thread-safe access to resources
/// by executing blocks of code within a lock, ensuring mutual exclusion.
protocol LockQueuing: Sendable {

    /// Executes a block within a lock, ensuring exclusive access.
    ///
    /// This method should guarantee that only one thread can execute the
    /// provided block at a time, using the underlying lock mechanism.
    ///
    /// - Parameter block: The block of code to execute safely within the lock.
    /// - Returns: The value returned by the block, if any.
    /// - Throws: Rethrows any errors thrown by the block.
    func sync<T>(_ block: () throws -> T) rethrows -> T
}
