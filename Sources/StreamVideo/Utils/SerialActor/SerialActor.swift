//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A serial actor that ensures tasks are executed one at a time in order.
///
/// `SerialActor` provides a thread-safe mechanism for executing asynchronous
/// tasks serially using Swift's actor model. It leverages a custom
/// `DispatchQueueExecutor` to maintain execution order and prevent race
/// conditions when accessing shared resources.
///
/// The actor implements the `@unchecked Sendable` protocol to allow safe
/// concurrent access while maintaining serial execution guarantees through
/// its underlying dispatch queue executor.
///
/// ## Usage
///
/// ```swift
/// let serialActor = SerialActor()
///
/// // Execute tasks serially
/// let result = try await serialActor.execute {
///     // Your async work here
///     return someValue
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations on this actor are thread-safe. Tasks submitted via the
/// `execute` method will be queued and executed in the order they were
/// submitted, ensuring no concurrent execution of tasks.
actor SerialActor: @unchecked Sendable {
    /// The underlying serial queue executor that manages task scheduling.
    ///
    /// This executor ensures that all tasks are executed serially on a
    /// dedicated dispatch queue, maintaining the order of execution and
    /// preventing race conditions.
    private let serialExecutor: DispatchQueueExecutor

    /// Initializes a new serial actor with a unique dispatch queue.
    ///
    /// - Parameter file: The source file creating this actor, used for
    ///   generating a unique queue label. Defaults to the calling file.
    ///
    /// The queue label is automatically generated using the provided file
    /// parameter to ensure uniqueness across different parts of the codebase.
    init(file: StaticString = #file) {
        self.init(queue: DispatchQueue(label: "io.getstream.serial.actor.\(file)"))
    }

    init(queue: DispatchQueue) {
        self.serialExecutor = .init(queue: queue)
    }

    /// The unowned serial executor for this actor.
    ///
    /// This property provides access to the underlying executor in an unowned
    /// form, which is required by Swift's actor system for task scheduling.
    /// The executor ensures all tasks run serially on the actor's queue.
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        serialExecutor.asUnownedSerialExecutor()
    }

    /// Cancels all pending tasks in the executor's queue.
    ///
    /// This method immediately cancels any tasks that are waiting to be
    /// executed but have not yet started. Tasks that are currently running
    /// will complete normally, but no new tasks will be processed.
    ///
    /// This is a non-isolated method, meaning it can be called from any
    /// context without requiring actor isolation.
    nonisolated func cancel() {
        serialExecutor.cancelAll()
    }

    /// Schedules a block to run serially on the actor's executor.
    ///
    /// - Parameter block: The asynchronous block to execute. Must be sendable
    ///   and can throw errors.
    /// - Returns: The result of the executed block.
    /// - Throws: Rethrows any error thrown by the provided block.
    ///
    /// This method ensures that the provided block is executed serially with
    /// respect to other tasks submitted to this actor. The block will be
    /// queued and executed in the order it was submitted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try await serialActor.execute {
    ///     // Perform some async work
    ///     let data = try await fetchData()
    ///     return processData(data)
    /// }
    /// ```
    nonisolated func execute<T: Sendable>(
        _ block: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        let token = serialExecutor.registerJob()
        return try await withTaskCancellationHandler(operation: {
            if token.isCancelled {
                throw CancellationError()
            } else {
                try await block()
            }
        }, onCancel: {}, isolation: self)
    }
}
