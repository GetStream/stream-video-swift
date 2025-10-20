//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A lightweight handle for dispatched store actions.
///
/// `StoreTask` coordinates the execution of one or more actions via
/// ``StoreExecutor`` and ``StoreCoordinator``. Callers can
/// dispatch-and-forget using `run(...)` and optionally await completion
/// or failure later with ``result()``.
///
/// - Note: This type is `Sendable`. Progress is tracked internally via a
///   `CurrentValueSubject` which is only mutated within the task's
///   execution context.
final class StoreTask<Namespace: StoreNamespace>: Sendable {
    // MARK: - Private Types

    /// Internal lifecycle states for the task.
    private enum State { case idle, running, completed, failed(Error) }

    private let executor: StoreExecutor<Namespace>
    private let coordinator: StoreCoordinator<Namespace>
    private let resultSubject: CurrentValueSubject<State, Never> = .init(.idle)

    init(
        executor: StoreExecutor<Namespace>,
        coordinator: StoreCoordinator<Namespace>
    ) {
        self.executor = executor
        self.coordinator = coordinator
    }

    // MARK: - Execution

    /// Executes the given actions through the store pipeline.
    ///
    /// The task transitions to `.running`, delegates to the
    /// ``StoreExecutor`` and ``StoreCoordinator``, and records completion
    /// or failure. Errors are captured and can be retrieved by awaiting
    /// ``result()``.
    ///
    /// - Parameters:
    ///   - identifier: Store identifier for logging context.
    ///   - state: Current state snapshot before processing.
    ///   - actions: Actions to execute, each optionally delayed.
    ///   - reducers: Reducers to apply in order.
    ///   - middleware: Middleware for side effects.
    ///   - logger: Logger used for diagnostics.
    ///   - subject: Subject that publishes updated state.
    ///   - file: Source file of the dispatch call.
    ///   - function: Function name of the dispatch call.
    ///   - line: Line number of the dispatch call.
    func run(
        identifier: String,
        state: Namespace.State,
        actions: [StoreActionBox<Namespace.Action>],
        reducers: [Reducer<Namespace>],
        middleware: [Middleware<Namespace>],
        logger: StoreLogger<Namespace>,
        subject: CurrentValueSubject<Namespace.State, Never>,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async {
        resultSubject.send(.running)
        do {
            var updatedState = state
            for action in actions {
                guard
                    coordinator.shouldExecute(
                        action: action.wrappedValue,
                        state: updatedState
                    )
                else {
                    logger.didSkip(
                        identifier: identifier,
                        action: action.wrappedValue,
                        state: updatedState,
                        file: file,
                        function: function,
                        line: line
                    )
                    continue
                }

                updatedState = try await executor.run(
                    identifier: identifier,
                    state: updatedState,
                    action: action,
                    reducers: reducers,
                    middleware: middleware,
                    logger: logger,
                    subject: subject,
                    file: file,
                    function: function,
                    line: line
                )
            }
            resultSubject.send(.completed)
        } catch {
            resultSubject.send(.failed(error))
        }
    }

    // MARK: - Results

    /// Suspends until the task completes or fails.
    ///
    /// - Throws: The error produced during execution, if any.
    /// - Returns: Void on success.
    func result() async throws {
        let result = try await resultSubject
            .filter {
                switch $0 {
                case .completed, .failed:
                    return true
                default:
                    return false
                }
            }
            .nextValue()

        switch result {
        case .completed:
            return
        case let .failed(error):
            throw error
        default:
            return
        }
    }
}
