//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Extension to `Publisher` providing utility methods for handling asynchronous
/// tasks and managing their lifecycle using `Combine`.
extension Publisher where Output: Sendable {
    /// Creates a task to handle the publisher's output asynchronously, with
    /// optional management of its lifecycle.
    ///
    /// - Parameters:
    ///   - disposableBag: An optional `DisposableBag` to store the task for
    ///     lifecycle management. Defaults to `nil`.
    ///   - identifier: An optional unique identifier for the task when stored
    ///     in a `DisposableBag`. Defaults to `nil`.
    ///   - receiveCompletion: A closure called upon completion of the publisher
    ///     with either a success or failure. Defaults to a no-op closure.
    ///   - receiveValue: A closure to asynchronously process the publisher's
    ///     output. The closure supports throwing errors.
    /// - Returns: An `AnyCancellable` to manage the subscription to the publisher.
    ///
    /// - Note:
    ///   - If the task is cancelled, a `CancellationError` is handled, and an
    ///     optional custom error (`ClientError`) can be propagated as a failure.
    ///   - Errors during task execution are logged using `LogConfig.logger`.
    public func sinkTask(
        storeIn disposableBag: DisposableBag,
        identifier: String = UUIDProviderKey.currentValue.get().uuidString,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        receiveCompletion: @escaping (@Sendable (Subscribers.Completion<Failure>) -> Void) = { _ in },
        receiveValue: @escaping (@Sendable (Output) async throws -> Void)
    ) -> AnyCancellable {
        // Subscribe to the publisher's events and process the received input.
        sink(receiveCompletion: receiveCompletion) { @Sendable [weak disposableBag] input in
            guard let disposableBag else {
                if let error = ClientError("Lifecycle error.") as? Failure {
                    receiveCompletion(.failure(error))
                }
                return
            }
            // Create a new task to handle the received value.
            Task(
                disposableBag: disposableBag,
                identifier: identifier,
                file: file,
                function: function,
                line: line
            ) {
                do {
                    // Check for task cancellation and process the value.
                    try Task.checkCancellation()
                    try await receiveValue(input)
                } catch let error as Failure {
                    // Handle specific failure cases.
                    receiveCompletion(.failure(error))
                } catch is CancellationError {
                    // Handle task cancellation as a failure with a custom error.
                    if let error = ClientError("Task was cancelled.") as? Failure {
                        receiveCompletion(.failure(error))
                    }
                } catch {
                    // Log any unexpected errors during task execution.
                    LogConfig.logger.error(ClientError(with: error))
                }
            }
        }
    }

    func sinkTask(
        queue: OperationQueue,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        receiveCompletion: @escaping (@Sendable (Subscribers.Completion<Failure>) -> Void) = { _ in },
        receiveValue: @escaping (@Sendable (Output) async throws -> Void)
    ) -> AnyCancellable {
        // Subscribe to the publisher's events and process the received input.
        sink(receiveCompletion: receiveCompletion) { [weak queue] input in
            guard let queue else {
                // Skip processing if the queue is unavailable.
                return
            }
            let capturedInput = input
            // Schedule the task on the provided serial actor queue.
            queue.addTaskOperation(file: file, function: function, line: line) {
                do {
                    // Check for task cancellation and process the value.
                    try Task.checkCancellation()
                    try await receiveValue(capturedInput)
                } catch let error as Failure {
                    // Handle specific failure cases.
                    receiveCompletion(.failure(error))
                } catch is CancellationError {
                    // Handle task cancellation as a failure with a custom error.
                    if let error = ClientError("Task was cancelled.") as? Failure {
                        receiveCompletion(.failure(error))
                    }
                } catch {
                    // Log any unexpected errors during task execution.
                    LogConfig.logger.error(error)
                }
            }
        }
    }

    /// Subscribes to the publisher and executes each received value using the
    /// provided actor, ensuring the handler is executed on the actor context.
    ///
    /// - Parameters:
    ///   - actor: The actor on which to execute the handler.
    ///   - disposableBag: The `DisposableBag` to track and manage task lifecycle.
    ///   - handler: An async closure that receives the actor and the output value.
    /// - Returns: An `AnyCancellable` for managing the subscription.
    func sinkTask<ActorType: Actor>(
        on actor: ActorType,
        storeIn disposableBag: DisposableBag,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        handler: @escaping @Sendable (ActorType, Output) async -> Void
    ) -> AnyCancellable {
        sink(receiveCompletion: { _ in }) { @Sendable [weak actor] input in
            guard let actor else {
                return
            }
            Task(
                disposableBag: disposableBag,
                file: file,
                function: function,
                line: line
            ) {
                do {
                    try Task.checkCancellation()
                    await handler(actor, input)
                } catch is CancellationError {
                    if let error = ClientError("Task was cancelled.") as? Failure {
                        LogConfig.logger.error(error)
                    }
                } catch {
                    LogConfig.logger.error(ClientError(with: error))
                }
            }
        }
    }
}
