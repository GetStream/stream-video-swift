//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

actor SerialActor {
    /// Declare a private variable to store the previous task.
    private var previousTask: Task<Void, Error>?
    private let disposableBag = DisposableBag()

    deinit {
        disposableBag.removeAll()
        previousTask = nil
    }

    nonisolated func cancel() {
        disposableBag.removeAll()
    }

    /// Executes a block of code asynchronously in a serial manner.
    ///
    /// This method ensures that only one operation runs at a time within this actor.
    /// It waits for the previous operation to finish before starting the next one.
    ///
    /// - Parameters:
    ///   - block: A block of code to execute asynchronously. The block is declared as
    ///     `Sendable`, meaning it can be safely sent across threads, and `escaping`,
    ///     meaning it can be executed asynchronously. The block can return any value
    ///     and can throw errors.
    ///
    /// - Throws: Any error thrown by the provided block.
    /// - Returns: The value returned by the provided block.
    func execute<T: Sendable>(_ block: @Sendable @escaping () async throws -> T) async throws -> T {
        /// Create a new task that runs the provided block of code within a closure.
        /// This closure captures the `previousTask` variable by value.
        let task = Task<T, Error> { [previousTask] in
            /// Wait for the previous task to finish by awaiting its result.
            /// If the previous task is nil, this line does nothing.
            _ = await previousTask?.result

            try Task.checkCancellation()

            /// Execute the provided block of code and re-throw any errors.
            return try await block()
        }
        task.store(in: disposableBag)

        /// Create a void task that we can store for synchronization
        let voidTask = Task<Void, Error> {
            _ = try await task.value
        }
        voidTask.store(in: disposableBag)

        /// Update the `previousTask` variable to point to the void task.
        previousTask = voidTask

        try Task.checkCancellation()
        
        /// Wait for the newly created task to finish by awaiting its value.
        /// This will re-throw any errors thrown by the block.
        return try await task.value
    }
}
