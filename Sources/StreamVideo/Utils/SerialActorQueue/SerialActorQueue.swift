//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
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
    public typealias Operation = @isolated(any) () async throws -> Void
    #else
    /// Type alias for a generic actor-isolated asynchronous operation.
    /// Uses `@isolated(any)` on Swift 6 or `@Sendable` fallback for older compilers.
    public typealias Operation = @Sendable() async throws -> Void
    #endif

    /// A task wrapper used internally by `SerialActorQueue` to represent a unit
    /// of work to be executed serially.
    public final class QueueTask: @unchecked Sendable {
        fileprivate let file: StaticString
        fileprivate let function: StaticString
        fileprivate let line: UInt
        fileprivate let queue = UnfairQueue()
        private let operation: Operation

        init(
            file: StaticString,
            function: StaticString,
            line: UInt,
            operation: @escaping Operation
        ) {
            self.file = file
            self.function = function
            self.line = line
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

    /// Holds cancellable task references for cleanup.
    private let disposableBag = DisposableBag()

    private let executor: DispatchQueueExecutor
    private let subject: PassthroughSubject<QueueTask, Never> = .init()
    private nonisolated(unsafe) var subscriptionCancellable: AnyCancellable?

    nonisolated public var unownedExecutor: UnownedSerialExecutor { .init(ordinary: executor) }

    /// Initializes the serial actor queue and launches the main task loop.
    public init(file: StaticString = #file) {
        self.executor = .init(file: file)
        subscriptionCancellable = subject
            .sinkTask(on: self, storeIn: disposableBag) { await $0.execute($1) }
    }

    /// Cleans up task references and finalizes the task stream.
    deinit {
        subscriptionCancellable?.cancel()
        disposableBag.removeAll()
    }

    private func execute(_ task: QueueTask) async {
        do {
            try Task.checkCancellation()
            try await task.run()
            log.debug(
                "Task completed.",
                functionName: task.function,
                fileName: task.file,
                lineNumber: task.line
            )
        } catch {
            log.error(
                "Task failed.",
                error: error,
                functionName: task.function,
                fileName: task.file,
                lineNumber: task.line
            )
        }
    }

    #if compiler(<6.0)
    /// Submit a throwing operation to the queue.
    @discardableResult
    public nonisolated func async(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        @_inheritActorContext operation: @escaping Operation
    ) -> QueueTask {
        let queueTask = QueueTask(
            file: file,
            function: function,
            line: line,
            operation: operation
        )

        subject.send(queueTask)

        return queueTask
    }

    /// Submit an operation to the queue.
    @discardableResult
    public nonisolated func async(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        @_inheritActorContext operation: @escaping @Sendable() async -> Void
    ) -> QueueTask {
        let queueTask = QueueTask(
            file: file,
            function: function,
            line: line,
            operation: operation
        )

        subject.send(queueTask)

        return queueTask
    }

    /// Executes an actor-isolated operation and awaits its result.
    ///
    /// - Parameter operation: A throwing async closure isolated to any actor.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    @discardableResult
    public nonisolated func sync<Output: Sendable>(
        @_inheritActorContext operation: @escaping @Sendable() async throws -> Output
    ) async throws -> Output {
        try await operation()
    }
    #else
    /// Submit an operation to the queue.
    @discardableResult
    public nonisolated func async<Failure>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        @_inheritActorContext operation: sending @escaping @Sendable @isolated(any) () async throws (Failure) -> Void
    ) -> QueueTask {
        let queueTask = QueueTask(
            file: file,
            function: function,
            line: line,
            operation: operation
        )

        subject.send(queueTask)

        return queueTask
    }

    /// Executes an actor-isolated operation and awaits its result.
    ///
    /// - Parameter operation: A throwing async closure isolated to any actor.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    @discardableResult
    public nonisolated func sync<Failure, Output: Sendable>(
        @_inheritActorContext operation: sending @escaping @Sendable @isolated(any) () async throws (Failure) -> Output
    ) async throws -> Output {
        try await operation()
    }
    #endif

    /// Cancels all enqueued and executing operations in the queue.
    ///
    /// Finishes the stream and removes the main task from the disposable bag.
    ///
    /// - Note: Once cancelled a queue cannot be started again.
    public nonisolated func cancelAll() {
        disposableBag.removeAll()
    }
}
