//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Executes store actions by coordinating middleware, reducers, and
/// logging.
///
/// The executor is responsible for the complete action processing
/// pipeline:
/// 1. Applying optional delay before processing
/// 2. Running middleware for side effects
/// 3. Processing reducers to generate new state
/// 4. Logging the results
/// 5. Publishing state updates
/// 6. Applying optional delay after processing
///
/// ## Thread Safety
///
/// The executor itself is not thread-safe. Thread safety should be
/// managed by the calling store through serial execution queues.
///
/// - Note: This is an internal component of the store architecture and
///   should not be used directly.
class StoreExecutor<Namespace: StoreNamespace>: @unchecked Sendable {

    /// Executes a single action through the store pipeline.
    ///
    /// This method orchestrates the complete action processing flow,
    /// ensuring proper ordering of operations and error handling.
    ///
    /// - Parameters:
    ///   - identifier: The store identifier for logging.
    ///   - state: The current state before processing.
    ///   - action: The boxed action to process (optionally delayed).
    ///   - delay: Configuration for delays before and after processing.
    ///   - reducers: Array of reducers to apply to the action.
    ///   - middleware: Array of middleware for side effects.
    ///   - logger: Logger for recording action results.
    ///   - subject: Publisher to emit the new state.
    ///   - file: Source file of the action dispatch.
    ///   - function: Function name of the action dispatch.
    ///   - line: Line number of the action dispatch.
    ///
    /// - Throws: Any error thrown by reducers during processing.
    ///
    /// - Note: The execution flow is:
    ///   1. Apply `delay.before` if specified
    ///   2. Notify middleware of the action
    ///   3. Process reducers to generate new state
    ///   4. Publish the new state
    ///   5. Apply `delay.after` if specified (only on success)
    func run(
        identifier: String,
        state: Namespace.State,
        action: StoreActionBox<Namespace.Action>,
        reducers: [Reducer<Namespace>],
        middleware: [Middleware<Namespace>],
        logger: StoreLogger<Namespace>,
        subject: CurrentValueSubject<Namespace.State, Never>,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> Namespace.State {
        // Apply optional delay before processing action
        await action.applyDelayBeforeIfRequired()

        // Notify all middleware about the action
        middleware.forEach {
            $0.apply(
                state: state,
                action: action.wrappedValue,
                file: file,
                function: function,
                line: line
            )
        }

        do {
            // Process action through all reducers sequentially
            let updatedState = try await reducers
                .asyncReduce(state) {
                    try await $1.reduce(
                        state: $0,
                        action: action.wrappedValue,
                        file: file,
                        function: function,
                        line: line
                    )
                }

            // Log successful completion
            logger.didComplete(
                identifier: identifier,
                action: action.wrappedValue,
                state: updatedState,
                file: file,
                function: function,
                line: line
            )

            // Publish new state to observers
            subject.send(updatedState)

            // Apply optional delay after successful processing
            await action.applyDelayAfterIfRequired()

            return updatedState
        } catch {
            // Log failure and rethrow
            logger.didFail(
                identifier: identifier,
                action: action.wrappedValue,
                error: error,
                file: file,
                function: function,
                line: line
            )
            throw error
        }
    }
}
