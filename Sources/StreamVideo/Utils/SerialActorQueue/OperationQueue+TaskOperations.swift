//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension OperationQueue {
    public convenience init(maxConcurrentOperationCount: Int = 0) {
        self.init()
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }

    /// Adds an asynchronous task operation to the queue without expecting a
    /// return value. Errors thrown by the operation are logged.
    ///
    /// - Parameters:
    ///   - file: The file where the operation was initiated.
    ///   - function: The function where the operation was initiated.
    ///   - line: The line number where the operation was initiated.
    ///   - operation: The async operation to be executed.
    #if compiler(>=6.0)
    public func addTaskOperation(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: sending @escaping @Sendable @isolated(any) () async throws -> Void
    ) {
        addOperation(
            TaskOperation(
                file: file,
                function: function,
                line: line,
                operation: operation
            )
        )
    }
    #else
    public func addTaskOperation(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        addOperation(
            TaskOperation<Void>(
                file: file,
                function: function,
                line: line,
                operation: operation
            )
        )
    }
    #endif

    /// Adds an asynchronous task operation to the queue and awaits its result.
    ///
    /// - Parameters:
    ///   - file: The file where the operation was initiated.
    ///   - function: The function where the operation was initiated.
    ///   - line: The line number where the operation was initiated.
    ///   - timeout: The time to wait for the operation result.
    ///   - operation: The async operation returning a value.
    /// - Returns: The result produced by the operation.
    /// - Throws: An error if the operation fails or times out.
    #if compiler(>=6.0)
    public func addSynchronousTaskOperation<Output: Sendable>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: sending @escaping @Sendable @isolated(any) () async throws -> Output
    ) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            addOperation(
                TaskOperation(
                    file: file,
                    function: function,
                    line: line,
                    continuation: continuation,
                    operation: operation
                )
            )
        }
    }
    #else
    public func addSynchronousTaskOperation<Output: Sendable>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: @escaping @Sendable () async throws -> Output
    ) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            addOperation(
                TaskOperation(
                    file: file,
                    function: function,
                    line: line,
                    continuation: continuation,
                    operation: operation
                )
            )
        }
    }
    #endif
}

private final class TaskOperation<Output: Sendable>: Operation, @unchecked Sendable {
    #if compiler(>=6.0)
    typealias Block = @Sendable @isolated(any) () async throws -> Output
    #else
    typealias Block = @Sendable () async throws -> Output
    #endif

    private let file: StaticString
    private let function: StaticString
    private let line: UInt

    private let operation: Block
    private let continuation: CheckedContinuation<Output, Error>?
    private var task: Task<Void, Never>?

    @Atomic private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        get { _isExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    @Atomic private var _isFinished: Bool = false
    override var isFinished: Bool {
        get { _isFinished }
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    @Atomic private var _isCancelled: Bool = false
    override var isCancelled: Bool {
        get { _isCancelled }
        set {
            willChangeValue(forKey: "isCancelled")
            _isCancelled = newValue
            didChangeValue(forKey: "isCancelled")
        }
    }

    #if compiler(>=6.0)
    init(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        continuation: CheckedContinuation<Output, Error>? = nil,
        operation: sending @escaping Block
    ) {
        self.file = file
        self.function = function
        self.line = line
        self.continuation = continuation
        self.operation = operation
    }
    #else
    init(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        continuation: CheckedContinuation<Output, Error>? = nil,
        operation: @escaping Block
    ) {
        self.file = file
        self.function = function
        self.line = line
        self.continuation = continuation
        self.operation = operation
    }
    #endif

    deinit {
        task?.cancel()
        task = nil
    }

    override func start() {
        guard !isCancelled else {
            isFinished = true
            return
        }
        isExecuting = true
        // swiftlint:disable discourage_task_init
        task = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                try Task.checkCancellation()
                let result = try await self.operation()
                if let continuation {
                    continuation.resume(returning: result)
                }
            } catch {
                if let continuation {
                    continuation.resume(throwing: error)
                }
                log.error(
                    error,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
            isExecuting = false
            isFinished = true
        }
        // swiftlint:enable discourage_task_init
    }

    override func cancel() {
        super.cancel()
        task?.cancel()
        task = nil
    }
}
