//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A thread-safe utility for executing asynchronous tasks serially.
///
/// `SerialActorQueue` ensures that tasks submitted to it are executed one at
/// a time, in the order they are received. This is particularly useful for
/// managing shared resources or maintaining a predictable task execution order.
public final class SerialActorQueue: Sendable {

    /// The internal serial actor responsible for task execution.
    /// This actor ensures tasks are run serially.
    private let actor = SerialActor()

    /// A disposableBag to keep track of the nested tasks. On deallocation allows us to cancel them
    /// and stop any execution.
    private let disposableBag = DisposableBag()

    /// Initializes a new `SerialActorQueue` instance.
    public init() {}

    deinit {
        actor.cancel()
        disposableBag.removeAll()
    }

    public func cancelAll() {
        actor.cancel()
        disposableBag.removeAll()
    }

    /// Submits an asynchronous task to be executed serially.
    ///
    /// - Parameters:
    ///   - file: The file from which the method is called. Defaults to `#file`.
    ///   - functionName: The function name from which the method is called. Defaults to `#function`.
    ///   - line: The line number from which the method is called. Defaults to `#line`.
    ///   - block: The task to execute. This block must be asynchronous and throwable.
    ///
    /// This method logs any errors encountered during the execution of the task.
    public func async(
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line,
        _ block: @Sendable @escaping () async throws -> Void
    ) {
        Task {
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
        }.store(in: disposableBag)
    }

    /// Submits an asynchronous task to be executed serially and waits for it to complete.
    ///
    /// - Parameter block: The task to execute. This block must be asynchronous and throwable.
    /// - Throws: Rethrows any error encountered during the execution of the task.
    /// - Returns: The value returned by the provided block.
    ///
    /// Use this method when you need to wait for the completion of the submitted task
    /// and handle its results or errors immediately.
    public func sync<T: Sendable>(
        _ block: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // Execute the task serially and wait for its completion.
        try await actor.execute(block)
    }
}
