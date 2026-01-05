//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An extension to the `Task` type that adds timeout functionality.
extension Task where Failure == any Error {
    @discardableResult
    init(
        priority: TaskPriority? = nil,
        /// New: a timeout property to configure how long a task may perform before failing with a timeout error.
        timeoutInSeconds: TimeInterval,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        operation: @Sendable @escaping () async throws -> Success
    ) {
        self = Task(priority: priority) {
            try await withThrowingTaskGroup(of: Success.self) { group in

                /// Add the operation to perform as the first task.
                _ = group.addTaskUnlessCancelled {
                    try await operation()
                }

                if timeoutInSeconds > 0, timeoutInSeconds <= TimeInterval(UInt64.max) {
                    /// Add another task to trigger the timeout if it finishes earlier than our first task.
                    _ = group.addTaskUnlessCancelled { () -> Success in
                        try await Task<Never, Never>.sleep(nanoseconds: UInt64(timeoutInSeconds * 1_000_000_000))
                        throw ClientError("Operation timed out", file, line)
                    }
                } else {
                    log.warning("Invalid timeout:\(timeoutInSeconds) was passed to Task.timeout. Task will timeout immediately.")
                    throw ClientError("Operation timed out", file, line)
                }

                /// We need to deal with an optional, even though we know it's not optional.
                /// This is default for task groups to account for when there aren't any pending tasks.
                /// Awaiting on an empty group immediately returns 'nil' without suspending.
                guard let result = try await group.next() else {
                    throw ClientError("Task produced no value", file, line)
                }

                /// If we reach this, it means we have a value before the timeout.
                /// We cancel the group, which means just cancelling the timeout task.
                group.cancelAll()
                return result
            }
        }
    }
}
