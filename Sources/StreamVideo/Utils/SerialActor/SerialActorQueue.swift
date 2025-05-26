//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A thread-safe utility for executing asynchronous tasks serially.
///
/// `SerialActorQueue` ensures that tasks submitted to it are executed one at
/// a time, in the order they are received. This is particularly useful for
/// managing shared resources or maintaining a predictable task execution order.
///
/// The queue leverages Swift's actor model internally through `SerialActor`
/// to provide thread-safe serial execution while offering both fire-and-forget
/// (`async`) and awaitable (`sync`) task submission methods.
///
/// ## Key Features
///
/// - **Serial Execution**: Tasks are executed one at a time in submission order
/// - **Thread Safety**: All operations are thread-safe and can be called from
///   any context
/// - **Cancellation Support**: Provides methods to cancel all pending tasks
/// - **Error Handling**: Automatic error logging for fire-and-forget tasks
/// - **Memory Management**: Automatic cleanup of completed tasks
///
/// ## Usage Examples
///
/// ### Fire-and-forget execution:
/// ```swift
/// let queue = SerialActorQueue()
///
/// queue.async {
///     // This task will be executed serially
///     await performSomeWork()
/// }
///
/// queue.async {
///     // This task will wait for the previous one to complete
///     await performMoreWork()
/// }
/// ```
///
/// ### Awaitable execution:
/// ```swift
/// let result = try await queue.sync {
///     // Wait for this task to complete and return its result
///     return await computeValue()
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods on this class are thread-safe and can be called concurrently
/// from multiple threads. The internal actor ensures that tasks are still
/// executed serially regardless of the calling context.
public final class SerialActorQueue: Sendable {

    /// The internal serial actor responsible for task execution.
    ///
    /// This actor ensures tasks are run serially by leveraging Swift's actor
    /// isolation model. All tasks submitted to the queue are forwarded to
    /// this actor for execution, maintaining the serial execution guarantee.
    private let actor = SerialActor()

    /// A disposable bag to keep track of nested tasks.
    ///
    /// This bag maintains references to all currently executing tasks created
    /// by the `async` method. On deallocation, it allows the queue to cancel
    /// all pending tasks and stop any ongoing execution, preventing memory
    /// leaks and ensuring clean shutdown.
    ///
    /// Each task is stored with a unique identifier that gets removed upon
    /// task completion, whether successful or failed.
    private let disposableBag = DisposableBag()

    /// Initializes a new `SerialActorQueue` instance.
    ///
    /// The queue is ready to accept tasks immediately after initialization.
    /// All internal components (actor and disposable bag) are set up and
    /// ready for use.
    public init() {}

    /// Cleans up resources when the queue is deallocated.
    ///
    /// This deinitializer ensures that all pending tasks are cancelled and
    /// the disposable bag is cleared, preventing any potential memory leaks
    /// or continued execution after the queue has been deallocated.
    deinit {
        actor.cancel()
        disposableBag.removeAll()
    }

    /// Cancels all pending and executing tasks.
    ///
    /// This method immediately cancels all tasks that are currently queued
    /// or executing within the serial actor. It also clears the disposable
    /// bag, removing references to all tracked tasks.
    ///
    /// After calling this method, the queue remains usable and can accept
    /// new tasks for execution.
    ///
    /// - Note: Tasks that are already running may complete before the
    ///   cancellation takes effect, depending on their current state.
    public func cancelAll() {
        actor.cancel()
        disposableBag.removeAll()
    }

    /// Submits an asynchronous task to be executed serially.
    ///
    /// This method provides fire-and-forget task execution. The task will be
    /// queued for serial execution, but the caller doesn't wait for its
    /// completion. Any errors encountered during execution are automatically
    /// logged using the provided source location information.
    ///
    /// - Parameters:
    ///   - file: The file from which the method is called. Used for error
    ///     logging. Defaults to `#file`.
    ///   - functionName: The function name from which the method is called.
    ///     Used for error logging. Defaults to `#function`.
    ///   - line: The line number from which the method is called. Used for
    ///     error logging. Defaults to `#line`.
    ///   - block: The asynchronous task to execute. This block must be
    ///     sendable and can throw errors.
    ///
    /// The task is wrapped in a `Task` and stored in the disposable bag with
    /// a unique identifier. Upon completion (successful or failed), the task
    /// is automatically removed from the bag.
    ///
    /// ## Error Handling
    ///
    /// Errors thrown by the task block are caught and logged automatically.
    /// Cancellation errors are ignored to avoid noise in logs when tasks
    /// are intentionally cancelled.
    ///
    /// ## Example
    ///
    /// ```swift
    /// queue.async {
    ///     try await performNetworkRequest()
    ///     updateUI()
    /// }
    /// ```
    public func async(
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line,
        _ block: @Sendable @escaping () async throws -> Void
    ) {
        let identifier = UUID().uuidString
        Task { [weak disposableBag] in
            do {
                try Task.checkCancellation()
                // Execute the task serially via the actor.
                try await actor.execute(block)
            } catch {
                if error is CancellationError { /* No-op */ }
                else {
                    // Log any errors encountered during task execution.
                    log.error(
                        error,
                        functionName: functionName,
                        fileName: file,
                        lineNumber: line
                    )
                }
            }
            disposableBag?.remove(identifier, cancel: false)
        }.store(in: disposableBag, key: identifier)
    }

    /// Submits an asynchronous task to be executed serially and waits for completion.
    ///
    /// This method provides synchronous-style task execution where the caller
    /// waits for the task to complete and can handle its results or errors
    /// immediately. The task is still executed serially with respect to other
    /// tasks in the queue.
    ///
    /// - Parameters:
    ///   - file: The file from which the method is called. Used for debugging
    ///     and error context. Defaults to `#file`.
    ///   - functionName: The function name from which the method is called.
    ///     Used for debugging and error context. Defaults to `#function`.
    ///   - line: The line number from which the method is called. Used for
    ///     debugging and error context. Defaults to `#line`.
    ///   - block: The asynchronous task to execute. This block must be
    ///     sendable and can throw errors.
    ///
    /// - Returns: The value returned by the provided block.
    /// - Throws: Rethrows any error encountered during the execution of the task.
    ///
    /// Unlike the `async` method, this method doesn't use the disposable bag
    /// since the caller is directly awaiting the result and managing the
    /// task lifecycle.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try await queue.sync {
    ///     let data = try await fetchData()
    ///     return processData(data)
    /// }
    /// print("Processing result: \(result)")
    /// ```
    ///
    /// ## Use Cases
    ///
    /// Use this method when you need to:
    /// - Wait for the completion of the submitted task
    /// - Handle the task's return value immediately
    /// - Propagate errors to the calling context
    /// - Ensure the task completes before continuing execution
    public func sync<T: Sendable>(
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line,
        _ block: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // Execute the task serially and wait for its completion.
        try await actor.execute(block)
    }
}
