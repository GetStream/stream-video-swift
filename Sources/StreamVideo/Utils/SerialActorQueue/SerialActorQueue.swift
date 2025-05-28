//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An actor-based serial queue that enqueues operations to run sequentially.
///
/// `SerialActorQueue` ensures that submitted operations are executed one at a
/// time, in order, using an `AsyncStream`-backed internal task loop.
/// Supports actor-isolated work by inheriting the actor context where needed.
///
/// - Note: The queue is backed by an AsyncStream continuation. Given that this maintains a Task
/// suspended (but still in the Alive state) it's good to keep an eye on the number of Alive tasks we have
/// when profiling the app.
public actor SerialActorQueue {
    #if compiler(>=6.0)
    /// Type alias for a generic actor-isolated asynchronous operation.
    /// Uses `@isolated(any)` on Swift 6 or `@Sendable` fallback for older compilers.
    typealias Operation = @isolated(any) () async throws -> Void
    #else
    /// Type alias for a generic actor-isolated asynchronous operation.
    /// Uses `@isolated(any)` on Swift 6 or `@Sendable` fallback for older compilers.
    typealias Operation = @Sendable() async throws -> Void
    #endif

    /// A task wrapper used internally by `SerialActorQueue` to represent a unit
    /// of work to be executed serially.
    public final class QueueTask: @unchecked Sendable {
        private let queue = UnfairQueue()
        let operation: Operation

        init(operation: @escaping Operation) {
            self.operation = operation
        }

        /// Runs the stored operation, checking for cancellation first.
        ///
        /// - Throws: Rethrows any error thrown by the operation.
        func run() async throws {
            try Task.checkCancellation()
            try await operation()
        }
    }

    /// Internal stream type used to drive the serial queue consumption.
    typealias Stream = AsyncStream<QueueTask>

    /// The continuation used to enqueue tasks into the async stream.
    private let continuation: Stream.Continuation
    /// Holds cancellable task references for cleanup.
    private let disposableBag = DisposableBag()

    /// Initializes the serial actor queue and launches the main task loop.
    public init() {
        let (stream, continuation) = Stream.makeStream()

        self.continuation = continuation

        Task(disposableBag: disposableBag, identifier: "main") {
            for await item in stream {
                try? Task.checkCancellation()
                try? await item.run()
            }
        }
    }

    /// Cleans up task references and finalizes the task stream.
    deinit {
        disposableBag.removeAll()
        continuation.finish()
    }

    #if compiler(<6.0)
    /// Submit a throwing operation to the queue.
    @discardableResult
    public nonisolated func async(
        @_inheritActorContext operation: @escaping Operation
    ) -> QueueTask {
        let queueTask = QueueTask(operation: operation)

        continuation.yield(queueTask)

        return queueTask
    }

    /// Submit an operation to the queue.
    @discardableResult
    public nonisolated func async(
        @_inheritActorContext operation: @escaping @Sendable() async -> Void
    ) -> QueueTask {
        let queueTask = QueueTask(operation: operation)

        continuation.yield(queueTask)

        return queueTask
    }
    #else
    /// Submit an operation to the queue.
    @discardableResult
    public nonisolated func async<Failure>(
        @_inheritActorContext operation: sending @escaping @isolated(any) () async throws (Failure) -> Void
    ) -> QueueTask {
        let queueTask = QueueTask(operation: operation)

        continuation.yield(queueTask)

        return queueTask
    }
    #endif

    /// Executes an actor-isolated operation and awaits its result.
    ///
    /// - Parameter operation: A throwing async closure isolated to any actor.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    @discardableResult
    public nonisolated func sync<Failure, Output: Sendable>(
        @_inheritActorContext operation: sending @escaping @isolated(any) () async throws (Failure) -> Output
    ) async throws -> Output {
        try await Task {
            try await operation()
        }.value
    }

    /// Cancels all enqueued and executing operations in the queue.
    ///
    /// Finishes the stream and removes the main task from the disposable bag.
    ///
    /// - Note: Once cancelled a queue cannot be started again.
    public nonisolated func cancelAll() {
        disposableBag.remove("main")
        continuation.finish()
    }
}
