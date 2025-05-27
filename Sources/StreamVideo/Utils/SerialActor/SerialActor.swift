//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

actor SerialActor {
    /// Declare a private variable to store the previous task.
    private let disposableBag = DisposableBag()
    private let executor: DispatchQueueExecutor
    nonisolated var unownedExecutor: UnownedSerialExecutor { .init(ordinary: executor) }

    init(file: StaticString = #file) {
        self.executor = .init(file: file)
    }

    deinit {
        disposableBag.removeAll()
    }

    nonisolated func cancel() {
        disposableBag.removeAll()
    }

    /// Executes a block of code asynchronously in a serial manner.
    ///
    /// This method ensures that only one operation runs at a time within this actor.
    /// It waits for the previous operation to finish before starting the next one.
    ///
    /// - Parameters:
    ///   - block: A block of code to execute asynchronously. The block is declared as
    ///     `Sendable`, meaning it can be safely sent across threads, and `escaping`,
    ///     meaning it can be executed asynchronously. The block can return any value
    ///     and can throw errors.
    ///
    /// - Throws: Any error thrown by the provided block.
    /// - Returns: The value returned by the provided block.
    func execute<T: Sendable>(_ block: @Sendable @escaping () async throws -> T) async throws -> T {
        try await block()
    }
}
