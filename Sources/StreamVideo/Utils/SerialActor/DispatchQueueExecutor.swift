//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A custom serial executor that manages task execution on a dispatch queue.
///
/// `DispatchQueueExecutor` implements Swift's `SerialExecutor` protocol to
/// provide ordered task execution using Grand Central Dispatch. It maintains
/// a queue of jobs and ensures they are executed serially while providing
/// cancellation capabilities for pending tasks.
///
/// The executor uses a dispatch queue as its underlying execution mechanism
/// and tracks enqueued jobs with unique identifiers to enable selective
/// cancellation of pending work.
///
/// ## Thread Safety
///
/// This class is marked as `@unchecked Sendable` because it manages its own
/// thread safety through the underlying dispatch queue and atomic operations
/// on the job tracking dictionary.
///
/// ## Usage
///
/// ```swift
/// let executor = DispatchQueueExecutor()
/// // Jobs will be automatically enqueued when used with Swift actors
/// ```
final class DispatchQueueExecutor: SerialExecutor, TaskExecutor, @unchecked Sendable {
    /// A token used to track and cancel individual enqueued jobs.
    ///
    /// Each job submitted to the executor gets an associated `CancelToken`
    /// that can be used to mark the job as cancelled before it begins
    /// execution. This provides fine-grained control over task cancellation.
    ///
    /// The token is thread-safe and uses simple boolean state to track
    /// cancellation status.
    final class CancelToken: @unchecked Sendable {
        /// Whether this token has been cancelled.
        ///
        /// Once set to `true`, the associated job should not be executed
        /// even if it's already been enqueued on the dispatch queue.
        fileprivate(set) var isCancelled = false

        /// Marks this token as cancelled.
        ///
        /// After calling this method, any job associated with this token
        /// should skip execution when it reaches the front of the queue.
        func cancel() { isCancelled = true }
    }

    /// The underlying dispatch queue that executes jobs serially.
    ///
    /// This queue ensures that all jobs are executed one at a time in the
    /// order they were submitted, providing the serial execution guarantee
    /// required by the `SerialExecutor` protocol.
    private let queue: DispatchQueue
    
    /// A dictionary tracking all currently enqueued jobs by their unique IDs.
    ///
    /// This atomic property maps job identifiers to their cancellation tokens,
    /// allowing the executor to cancel specific jobs before they execute.
    /// Jobs are automatically removed from this dictionary after execution.
    @Atomic private var enqueuedJobs: [UUID: CancelToken] = [:]

    /// Creates a new executor with an automatically generated queue label.
    ///
    /// - Parameter file: The source file creating this executor, used for
    ///   generating a unique queue label. Defaults to the calling file.
    ///
    /// This convenience initializer creates a dispatch queue with a label
    /// based on the calling file to help with debugging and identification.
    convenience init(file: StaticString = #file) {
        self.init(queue: DispatchQueue(label: "io.getstream.serial.actor.\(file)"))
    }

    /// Creates a new executor with the specified dispatch queue.
    ///
    /// - Parameter queue: The dispatch queue to use for job execution.
    ///   This queue should typically be serial to maintain execution order.
    ///
    /// The provided queue becomes the execution context for all jobs
    /// submitted to this executor.
    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Enqueues a job for serial execution on the dispatch queue.
    ///
    /// - Parameter job: The unowned job to execute. This job will be run
    ///   synchronously on the executor when it reaches the front of the queue.
    ///
    /// This method is called by Swift's actor system when tasks need to be
    /// scheduled for execution. Each job gets a unique identifier and
    /// cancellation token for tracking purposes.
    ///
    /// Jobs are executed asynchronously on the dispatch queue, but the job
    /// itself runs synchronously once it begins execution to maintain the
    /// serial execution contract.
    func enqueue(_ job: UnownedJob) {
//        let identifier = UUID()
//        let cancelToken = CancelToken()
//        enqueuedJobs[identifier] = cancelToken

        queue.async { [weak self] in
            guard
                let self
            else {
                return
            }

            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func registerJob() -> CancelToken {
        let identifier = UUID()
        let cancelToken = CancelToken()
        enqueuedJobs[identifier] = cancelToken
        return cancelToken
    }

    /// Returns an unowned reference to this executor for use by the actor system.
    ///
    /// - Returns: An `UnownedSerialExecutor` wrapping this executor.
    ///
    /// This method is required by the `SerialExecutor` protocol and provides
    /// the actor system with an unowned reference to prevent retain cycles
    /// while still allowing the executor to manage job scheduling.
    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    /// Verifies that the current thread is executing on this executor's queue.
    ///
    /// This method uses `dispatchPrecondition` to assert that the calling
    /// code is running on the correct dispatch queue. It's primarily used
    /// for debugging and ensuring proper isolation in actor contexts.
    ///
    /// - Note: This method will trigger a runtime assertion failure if
    ///   called from the wrong queue in debug builds.
    func checkIsolated() {
        dispatchPrecondition(condition: .onQueue(queue))
    }

    /// Cancels all currently enqueued jobs.
    ///
    /// This method immediately removes all pending jobs from the tracking
    /// dictionary, effectively cancelling them before they can execute.
    /// Jobs that are already running will complete normally.
    ///
    /// After calling this method, the executor is ready to accept new jobs
    /// for execution.
    func cancelAll() {
        _enqueuedJobs.mutate { entries in
            entries
                .forEach { $0.value.isCancelled = true }
            return [:]
        }
    }
}
