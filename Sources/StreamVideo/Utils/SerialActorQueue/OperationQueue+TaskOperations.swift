//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension OperationQueue {
    public func addTaskOperation<Failure>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: sending @escaping @Sendable @isolated(any) () async throws (Failure) -> Void
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

    public func addSynchronousTaskOperation<Output: Sendable, Failure: Error>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        timeout: TimeInterval = 10,
        operation: sending @escaping @Sendable @isolated(any) () async throws (Failure) -> Output
    ) async throws -> Output {
        let subject = PassthroughSubject<Output, Error>()
        addOperation(
            TaskOperation(
                file: file,
                function: function,
                line: line,
                resultSubject: subject,
                operation: operation
            )
        )
        return try await subject.nextValue(timeout: timeout)
    }
}

private final class TaskOperation<Output: Sendable, Failure: Error>: Operation, @unchecked Sendable {
    typealias Block = @Sendable @isolated(any) () async throws (Failure) -> Output

    private let file: StaticString
    private let function: StaticString
    private let line: UInt

    private let operation: Block
    private let resultSubject: PassthroughSubject<Output, Failure>?
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

    init(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        resultSubject: PassthroughSubject<Output, Failure>? = nil,
        operation: sending @escaping Block
    ) {
        self.file = file
        self.function = function
        self.line = line
        self.resultSubject = resultSubject
        self.operation = operation
    }

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
                if let resultSubject {
                    resultSubject.send(result)
                    resultSubject.send(completion: .finished)
                }
            } catch {
                if let resultSubject, let error = error as? Failure {
                    resultSubject.send(completion: .failure(error))
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
