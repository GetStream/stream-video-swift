//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Runs two child tasks concurrently and returns their results in the same
/// order as the provided operations.
///
/// This helper differs from `async let` in an important way: child task
/// cancellation and completion are managed through an explicit task-group
/// object instead of compiler-generated lexical cleanup.
///
/// Why that matters:
/// - `async let` is ideal for short, local fan-out where the parent task is
///   guaranteed to await all children before the scope exits.
/// - When the parent task is stored and can be cancelled from the outside
///   during teardown, a task group gives us an explicit `cancelAll()` and a
///   clear place to drain child completion via `group.next()`.
///
/// Prefer this helper over `async let` when:
/// - The parent task can be cancelled externally while object teardown is in
///   progress.
/// - You want explicit control over sibling-task cancellation and completion.
///
/// Prefer `async let` when:
/// - The work is simple, local, and lexically scoped.
/// - The parent naturally awaits every child before leaving the scope.
/// - The extra task-group ceremony would add more complexity than value.
func withConcurrentChildrenTask<First: Sendable, Second: Sendable>(
    _ first: @Sendable @escaping () async throws -> First,
    _ second: @Sendable @escaping () async throws -> Second
) async throws -> (First, Second) {
    try await withThrowingTaskGroup(
        of: ConcurrentChildrenTaskResult<First, Second>.self,
        returning: (First, Second).self
    ) { group in
        defer { group.cancelAll() }

        group.addTask {
            try Task.checkCancellation()
            let value = try await first()
            try Task.checkCancellation()
            return .first(value)
        }

        group.addTask {
            try Task.checkCancellation()
            let value = try await second()
            try Task.checkCancellation()
            return .second(value)
        }

        var firstResult: First?
        var secondResult: Second?

        while let result = try await group.next() {
            switch result {
            case let .first(value):
                firstResult = value
            case let .second(value):
                secondResult = value
            }
        }

        guard let firstResult, let secondResult else {
            throw ClientError("Concurrent child tasks did not complete.")
        }

        return (firstResult, secondResult)
    }
}

private enum ConcurrentChildrenTaskResult<First: Sendable, Second: Sendable>: Sendable {
    case first(First)
    case second(Second)
}
