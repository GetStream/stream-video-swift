//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public extension Publisher where Output: Sendable {

    /// Converts the current publisher into an `AsyncStream` of its output.
    ///
    /// This allows you to consume any Combine publisher using Swift's `for await`
    /// syntax, providing a bridge between Combine and Swift Concurrency.
    ///
    /// - Returns: An `AsyncStream` emitting values of the publisher as they arrive.
    func eraseAsAsyncStream() -> AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = self.sink(
                receiveCompletion: { _ in
                    continuation.finish()
                },
                receiveValue: {
                    continuation.yield($0)
                }
            )

            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }

    /// Waits for the first value emitted by the publisher.
    ///
    /// If the publisher completes before emitting a value, the method throws
    /// `ClientError`. If the awaiting task is cancelled before a value is
    /// emitted, the method throws `CancellationError`.
    ///
    /// - Parameters:
    ///   - file: The file captured for error reporting.
    ///   - line: The line captured for error reporting.
    /// - Returns: The first emitted output value.
    func firstValue(
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Output {
        if #available(iOS 15.0, *) {
            for try await value in self.values {
                return value
            }
        } else {
            for try await value in eraseAsAsyncStream() {
                return value
            }
        }

        if Task<Never, Never>.isCancelled {
            throw CancellationError()
        }
        throw ClientError("Task produced no value.", file, line)
    }

    /// Waits for the first value emitted by the publisher within the provided
    /// timeout.
    ///
    /// Cancellation is propagated immediately to the underlying timed task so a
    /// cancelled caller does not continue waiting until the timeout elapses.
    ///
    /// - Parameters:
    ///   - timeoutInSeconds: The maximum time to wait for the first value.
    ///   - file: The file captured for error reporting.
    ///   - function: The function captured for error reporting.
    ///   - line: The line captured for error reporting.
    /// - Returns: The first emitted output value.
    func firstValue(
        timeoutInSeconds: TimeInterval,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Output {
        // Invariant: publisher used read-only in this async path.
        let erasedPublisher = eraseToAnyPublisher()
        let timeoutTask = Task(
            timeoutInSeconds: timeoutInSeconds,
            file: file,
            function: function,
            line: line
        ) {
            try await erasedPublisher.firstValue(file: file, line: line)
        }

        // Ensure callers that cancel while awaiting a timed publisher do not
        // leave the underlying timeout task running until the deadline.
        return try await withTaskCancellationHandler {
            try await timeoutTask.value
        } onCancel: {
            timeoutTask.cancel()
        }
    }

    /// Waits for the next emitted value, optionally skipping a number of
    /// earlier values first.
    ///
    /// - Parameters:
    ///   - dropFirst: The number of values to ignore before returning.
    ///   - timeout: An optional timeout for receiving the value.
    ///   - file: The file captured for error reporting.
    ///   - function: The function captured for error reporting.
    ///   - line: The line captured for error reporting.
    /// - Returns: The next emitted output value after applying `dropFirst`.
    func nextValue(
        dropFirst: Int = 0,
        timeout: TimeInterval? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Output {
        let publisher = dropFirst > 0
            ? self.dropFirst(dropFirst).eraseToAnyPublisher()
            : eraseToAnyPublisher()

        if let timeout {
            return try await publisher.firstValue(
                timeoutInSeconds: timeout,
                file: file,
                function: function,
                line: line
            )
        } else {
            return try await publisher.firstValue()
        }
    }
}
