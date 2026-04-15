//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Indicates how a two-task race completed.
///
/// `.first` and `.second` mean that side completed by returning a value or
/// throwing an error. `.cancelled` means the parent task was cancelled before
/// either side won the race.
///
/// - Important: The losing task is cancelled but not awaited. If it does not
/// cooperate with cancellation, it may continue running in the background after
/// this helper returns.
enum FirstTaskCompletedResult<First: Sendable, Second: Sendable>: @unchecked Sendable {
    case first(Result<First, Error>)
    case second(Result<Second, Error>)
    case cancelled
}

/// Runs two tasks concurrently and returns as soon as the race is resolved.
///
/// The race resolves when either operation returns, throws, or the parent task
/// is cancelled.
///
/// Unlike `withConcurrentChildrenTask`, this helper is intentionally
/// unstructured with respect to the competing operations: once the race is
/// resolved, the other operation is cancelled and the helper returns
/// immediately without awaiting the cancelled task.
///
/// Task handles are registered through a coordinator so a task created after
/// the race has already resolved is cancelled as soon as its handle is
/// observed, instead of being left running indefinitely.
///
/// Use this helper when waiting for the loser to finish would block an
/// important caller path, such as a timeout race.
func withFirstTaskCompleted<First: Sendable, Second: Sendable>(
    priority: TaskPriority? = nil,
    _ first: @Sendable @escaping () async throws -> First,
    _ second: @Sendable @escaping () async throws -> Second
) async -> FirstTaskCompletedResult<First, Second> {
    let coordinator = FirstTaskCompletedCoordinator<First, Second>()

    return await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
            coordinator.install(continuation)

            coordinator.setTask(
                for: .first,
                Task(priority: priority) {
                    let result: Result<First, Error>
                    do {
                        result = .success(try await first())
                    } catch {
                        result = .failure(error)
                    }

                    guard coordinator.resolve(.first(result)) else {
                        return
                    }

                    coordinator.cancelTask(for: .second)
                }
            )

            coordinator.setTask(
                for: .second,
                Task(priority: priority) {
                    let result: Result<Second, Error>
                    do {
                        result = .success(try await second())
                    } catch {
                        result = .failure(error)
                    }

                    guard coordinator.resolve(.second(result)) else {
                        return
                    }

                    coordinator.cancelTask(for: .first)
                }
            )
        }
    } onCancel: {
        guard coordinator.resolve(.cancelled) else {
            return
        }

        coordinator.cancelAll()
    }
}

/// Serializes result delivery and task-handle management for the race.
///
/// This closes the gap between result resolution and task registration by
/// cancelling any task whose handle is installed after the race has already
/// resolved.
private final class FirstTaskCompletedCoordinator<First: Sendable, Second: Sendable>: @unchecked Sendable {
    enum TaskKey { case first, second }
    typealias Result = FirstTaskCompletedResult<First, Second>

    private let queue = UnfairQueue()
    private var continuation: CheckedContinuation<Result, Never>?
    private var resolvedResult: Result?
    private var firstTask: Task<Void, Never>?
    private var secondTask: Task<Void, Never>?

    func install(_ continuation: CheckedContinuation<Result, Never>) {
        let resultToResume = queue.sync { () -> Result? in
            if let resolvedResult {
                return resolvedResult
            } else {
                self.continuation = continuation
                return nil
            }
        }

        if let resultToResume {
            continuation.resume(returning: resultToResume)
        }
    }

    @discardableResult
    func resolve(_ result: Result) -> Bool {
        let resolution = queue.sync { () -> (Bool, CheckedContinuation<Result, Never>?) in
            guard resolvedResult == nil else {
                return (false, nil)
            }

            resolvedResult = result
            let continuationToResume = continuation
            continuation = nil
            return (true, continuationToResume)
        }

        guard resolution.0 else {
            return false
        }

        resolution.1?.resume(returning: result)
        return true
    }

    func setTask(for taskKey: TaskKey, _ task: Task<Void, Never>) {
        let shouldCancel = queue.sync { () -> Bool in
            guard resolvedResult == nil else {
                return true
            }

            switch taskKey {
            case .first:
                firstTask = task
            case .second:
                secondTask = task
            }
            return false
        }

        if shouldCancel {
            task.cancel()
        }
    }

    func cancelTask(for taskKey: TaskKey) {
        let task = queue.sync {
            switch taskKey {
            case .first:
                let task = firstTask
                firstTask = nil
                return task
            case .second:
                let task = secondTask
                secondTask = nil
                return task
            }
        }

        task?.cancel()
    }

    func cancelAll() {
        cancelTask(for: .first)
        cancelTask(for: .second)
    }
}
