//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An extension to the `Task` type that adds timeout functionality.
extension Task where Failure == Error {
    /// An error type representing a timeout condition.
    enum TimeoutError: Error {
        /// Indicates that the operation has timed out.
        case timedOut
    }

    /// Initializes a new task with a timeout.
    ///
    /// This initializer creates a new task that will execute the given operation
    /// with a specified timeout. If the operation doesn't complete within the
    /// timeout period, a `TimeoutError` will be thrown.
    ///
    /// - Parameters:
    ///   - timeout: The maximum duration (in seconds) to wait for the operation to complete.
    ///   - operation: The asynchronous operation to perform.
    ///
    /// - Returns: A new `Task` instance that will execute the operation with the specified timeout.
    ///
    /// - Throws: `TimeoutError.timedOut` if the operation doesn't complete within the specified timeout.
    ///
    /// - Note: This implementation uses a task group to manage concurrent execution
    ///         of the main operation and the timeout timer.
    init(
        timeout: TimeInterval,
        operation: @Sendable @escaping () async throws -> Success
    ) {
        self.init {
            try await withThrowingTaskGroup(of: Success.self) { group in
                group.addTask {
                    try await operation()
                }
                group.addTask {
                    try await Task<Never, Never>.sleep(
                        nanoseconds: UInt64(
                            timeout * 1_000_000_000
                        )
                    )
                    throw TimeoutError.timedOut
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
        }
    }
}
