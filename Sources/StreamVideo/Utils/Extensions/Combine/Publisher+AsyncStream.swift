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
}
