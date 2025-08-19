//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine

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

        throw ClientError("Task produced no value.", file, line)
    }

    func firstValue(
        timeoutInSeconds: TimeInterval,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Output {
        nonisolated(unsafe) let selfReference = self
        return try await Task(
            timeoutInSeconds: timeoutInSeconds,
            file: file,
            function: function,
            line: line
        ) {
            try await selfReference.firstValue(file: file, line: line)
        }.value
    }

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
