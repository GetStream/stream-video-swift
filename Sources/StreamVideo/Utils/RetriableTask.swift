//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A helper that retries synchronous operations a fixed number of times.
enum RetriableTask {
    /// Runs the provided throwing operation up to the requested number of iterations.
    /// The call stops as soon as the operation succeeds, or rethrows the last error
    /// if all attempts fail.
    /// - Parameters:
    ///   - iterations: Maximum number of times the operation should be executed.
    ///   - operation: The work item to execute repeatedly until it succeeds.
    /// - Throws: The final error thrown by `operation` if it never succeeds.
    static func run(
        iterations: Int,
        operation: () throws -> Void
    ) throws {
        try execute(
            currentIteration: 0,
            iterations: iterations,
            operation: operation
        )
    }

    /// Recursively executes the operation, incrementing the iteration until
    /// the maximum is reached or the call succeeds.
    private static func execute(
        currentIteration: Int,
        iterations: Int,
        operation: () throws -> Void
    ) throws {
        do {
            return try operation()
        } catch {
            if currentIteration < iterations - 1 {
                do {
                    return try execute(
                        currentIteration: currentIteration + 1,
                        iterations: iterations,
                        operation: operation
                    )
                } catch {
                    throw error
                }
            } else {
                throw error
            }
        }
    }
}
