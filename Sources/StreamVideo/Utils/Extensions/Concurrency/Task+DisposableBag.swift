//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Foundation

/// Extension to Task for integration with a `DisposableBag`.
///
/// These initializers allow tasks to be automatically tracked and canceled
/// via a `DisposableBag`. The task is registered with a unique identifier
/// and removed upon completion.
extension Task {

    /// Initializes and stores a non-throwing task in the given `DisposableBag`.
    ///
    /// The task will be tracked using the provided identifier and removed from
    /// the bag upon completion.
    ///
    /// - Parameters:
    ///   - disposableBag: The bag responsible for managing task lifecycle.
    ///   - identifier: A unique key for the task. Defaults to a generated UUID.
    ///   - priority: Optional task priority.
    ///   - block: A non-throwing async closure representing the task body.
    @discardableResult
    public init(
        disposableBag: DisposableBag,
        identifier: String = UUIDProviderKey.currentValue.get().uuidString,
        priority: TaskPriority? = nil,
        subsystem: LogSubsystem = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        @_inheritActorContext block: @Sendable @escaping () async -> Success
    ) where Failure == Never {
        self.init(priority: priority) { [weak disposableBag] in
            defer { disposableBag?.completed(identifier) }
            return await trace.trace(
                subsystem: subsystem,
                file: file,
                function: function,
                line: line
            ) { await block() }
        }
        store(in: disposableBag, identifier: identifier)
    }

    /// Initializes and stores a throwing task in the given `DisposableBag`.
    ///
    /// The task will be tracked using the provided identifier and removed from
    /// the bag upon completion.
    ///
    /// - Parameters:
    ///   - disposableBag: The bag responsible for managing task lifecycle.
    ///   - identifier: A unique key for the task. Defaults to a generated UUID.
    ///   - priority: Optional task priority.
    ///   - block: A throwing async closure representing the task body.
    @discardableResult
    public init(
        disposableBag: DisposableBag,
        identifier: String = UUIDProviderKey.currentValue.get().uuidString,
        priority: TaskPriority? = nil,
        subsystem: LogSubsystem = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        @_inheritActorContext block: @Sendable @escaping () async throws -> Success
    ) where Failure == Error {
        self.init(priority: priority) { [weak disposableBag] in
            defer { disposableBag?.completed(identifier) }
            return try await trace.trace(
                subsystem: subsystem,
                file: file,
                function: function,
                line: line
            ) { try await block() }
        }
        store(in: disposableBag, identifier: identifier)
    }

    /// Stores a cancel handler for the task in the specified `DisposableBag`.
    ///
    /// - Parameters:
    ///   - disposableBag: The bag to insert the cancel handler into.
    ///   - identifier: A unique key under which the cancel handler is stored.
    public func store(
        in disposableBag: DisposableBag,
        identifier: String = UUID().uuidString
    ) {
        disposableBag.insert(.init(cancel), with: identifier)
    }
}
