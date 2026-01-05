//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
final class DispatchQueueExecutor: SerialExecutor, @unchecked Sendable {
    /// The underlying dispatch queue that executes jobs serially.
    ///
    /// This queue ensures that all jobs are executed one at a time in the
    /// order they were submitted, providing the serial execution guarantee
    /// required by the `SerialExecutor` protocol.
    let queue: DispatchQueue

    /// Creates a new executor with an automatically generated queue label.
    ///
    /// - Parameter file: The source file creating this executor, used for
    ///   generating a unique queue label. Defaults to the calling file.
    ///
    /// This convenience initializer creates a dispatch queue with a label
    /// based on the calling file to help with debugging and identification.
    convenience init(file: StaticString = #file) {
        self.init(queue: DispatchQueue(label: "io.getstream.serial.actor.\(URL(fileURLWithPath: "\(file)").lastPathComponent)"))
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
        let unownedSerialExecutor = asUnownedSerialExecutor()
        queue.async { job.runSynchronously(on: unownedSerialExecutor) }
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
}

#if compiler(>=6.0)
extension DispatchQueueExecutor: TaskExecutor {}
#endif
