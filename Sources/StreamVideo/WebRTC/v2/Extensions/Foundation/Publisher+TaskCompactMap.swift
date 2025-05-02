//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Extension to `Publisher` providing utility methods for handling asynchronous
/// tasks and managing their lifecycle using `Combine`.
extension Publisher where Output: Sendable {
    /// Creates a task to transform the publisher's output asynchronously, with
    /// optional management of its lifecycle.
    ///
    /// - Parameters:
    ///   - disposableBag: An optional `DisposableBag` to store the task for
    ///     lifecycle management. Defaults to `nil`.
    ///   - identifier: An optional unique identifier for the task when stored
    ///     in a `DisposableBag`. Defaults to `nil`.
    ///   - transform: A closure to asynchronously transform the publisher's
    ///     output. The closure supports throwing errors and returns an optional value.
    /// - Returns: A new publisher that emits the transformed values.
    ///
    /// - Note:
    ///   - If the task is cancelled, a `CancellationError` is handled.
    ///   - Errors during task execution are logged using `LogConfig.logger`.
    public func compactMapTask<T: Sendable>(
        storeIn disposableBag: DisposableBag? = nil,
        identifier: String? = nil,
        transform: @escaping (@Sendable(Output) async throws -> T?)
    ) -> AnyPublisher<T, Failure> {
        let subject = PassthroughSubject<T, Failure>()

        let cancellable = sink(
            receiveCompletion: { completion in
                subject.send(completion: completion)
            },
            receiveValue: { @Sendable [weak disposableBag] input in
                let task = Task {
                    do {
                        try Task.checkCancellation()
                        if let transformed = try await transform(input) {
                            subject.send(transformed)
                        }
                    } catch let error as Failure {
                        subject.send(completion: .failure(error))
                    } catch is CancellationError {
                        if let error = ClientError("Task was cancelled.") as? Failure {
                            subject.send(completion: .failure(error))
                        }
                    } catch {
                        LogConfig.logger.error(ClientError(with: error))
                    }
                }

                if let disposableBag {
                    task.store(in: disposableBag, key: identifier ?? UUID().uuidString)
                }
            }
        )

        return subject
            .handleEvents(receiveCancel: {
                cancellable.cancel()
            })
            .eraseToAnyPublisher()
    }
}
