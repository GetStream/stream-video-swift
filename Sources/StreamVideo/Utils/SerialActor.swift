//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

actor SerialActor {
    /// Declare a private variable to store the previous task.
    private var previousTask: Task<Void, Error>?

    /// Executes a block of code asynchronously in a serial manner.
    ///
    /// This method ensures that only one operation runs at a time within this actor.
    /// It waits for the previous operation to finish before starting the next one.
    ///
    /// - Parameters:
    ///   - block: A block of code to execute asynchronously. The block is declared as
    ///     `Sendable`, meaning it can be safely sent across threads, and `escaping`,
    ///     meaning it can be executed asynchronously. The block must return `Void`
    ///     (no value) and can throw errors.
    ///
    /// - Throws: Any error thrown by the provided block.
    func execute(_ block: @Sendable @escaping () async throws -> Void) async throws {
        /// Create a new task that runs the provided block of code within a closure.
        /// This closure captures the `previousTask` variable by value.
        let task = Task { [previousTask] in
            /// Wait for the previous task to finish by awaiting its result.
            /// If the previous task is nil, this line does nothing.
            _ = await previousTask?.result

            /// Execute the provided block of code and re-throw any errors.
            return try await block()
        }

        /// Update the `previousTask` variable to point to the newly created task.
        previousTask = task

        /// Wait for the newly created task to finish by awaiting its value.
        /// This will re-throw any errors thrown by the block.
        try await task.value
    }
}
