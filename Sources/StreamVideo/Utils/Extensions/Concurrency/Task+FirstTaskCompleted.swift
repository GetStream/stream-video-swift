//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Indicates which of two concurrently started tasks completed first.
///
/// Completion means the task either returned a value or threw an error.
///
/// - Important: The losing task is cancelled but not awaited. If it does not
/// cooperate with cancellation, it may continue running in the background after
/// this helper returns.
enum FirstTaskCompletedResult<First: Sendable, Second: Sendable>: @unchecked Sendable {
    case first(Result<First, Error>)
    case second(Result<Second, Error>)
    case cancelled
}

/// Runs two tasks concurrently and returns as soon as either one completes.
///
/// Unlike `withConcurrentChildrenTask`, this helper is intentionally
/// unstructured with respect to the competing operations: once one operation
/// completes, the other is cancelled and the helper returns immediately without
/// awaiting the cancelled task.
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

            coordinator.setFirstTask(
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

                    coordinator.cancelSecondTask()
                }
            )

            coordinator.setSecondTask(
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

                    coordinator.cancelFirstTask()
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

private final class FirstTaskCompletedCoordinator<First: Sendable, Second: Sendable>: @unchecked Sendable {
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

    func setFirstTask(_ task: Task<Void, Never>) {
        let shouldCancel = queue.sync { () -> Bool in
            firstTask = task
            return resolvedResult != nil
        }

        if shouldCancel {
            task.cancel()
        }
    }

    func setSecondTask(_ task: Task<Void, Never>) {
        let shouldCancel = queue.sync { () -> Bool in
            secondTask = task
            return resolvedResult != nil
        }

        if shouldCancel {
            task.cancel()
        }
    }

    func cancelFirstTask() {
        let task = queue.sync { firstTask }

        task?.cancel()
    }

    func cancelSecondTask() {
        let task = queue.sync { secondTask }

        task?.cancel()
    }

    func cancelAll() {
        cancelFirstTask()
        cancelSecondTask()
    }
}
