//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class Store<Namespace: StoreNamespace>: @unchecked Sendable {

    var state: Namespace.State { stateSubject.value }

    private let identifier: String
    private let logger: StoreLogger<Namespace>
    private let executor: StoreExecutor<Namespace>
    private let stateSubject: CurrentValueSubject<Namespace.State, Never>
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    @Atomic private(set) var reducers: [Reducer<Namespace>]
    @Atomic private(set) var middleware: [Middleware<Namespace>]

    init(
        identifier: String,
        initialState: Namespace.State,
        reducers: [Reducer<Namespace>],
        middleware: [Middleware<Namespace>],
        logger: StoreLogger<Namespace>,
        executor: StoreExecutor<Namespace>
    ) {
        self.identifier = identifier
        stateSubject = .init(initialState)
        self.reducers = reducers
        self.middleware = []
        self.logger = logger
        self.executor = executor

        middleware.forEach { add($0) }
    }

    // MARK: - Reducers

    /// Adds middleware to observe or intercept audio actions.
    func add<T: Middleware<Namespace>>(_ value: T) {
        guard middleware.first(where: { $0 === value }) == nil else {
            return
        }
        middleware.append(value)
        value.dispatcher = { [weak self] in self?.dispatch($0) }
        value.stateProvider = { [weak self] in self?.state }
    }

    /// Removes previously added middleware.
    func remove<T: Middleware<Namespace>>(_ value: T) {
        middleware = middleware.filter { $0 !== value }
        value.dispatcher = nil
        value.stateProvider = nil
    }

    // MARK: - Reducers

    /// Adds a reducer to handle audio session actions.
    func add<T: Reducer<Namespace>>(_ value: T) {
        guard reducers.first(where: { $0 === value }) == nil else {
            return
        }
        reducers.append(value)
    }

    /// Adds a reducer to handle audio session actions.
    func remove<T: Reducer<Namespace>>(_ value: T) {
        reducers = reducers.filter { $0 !== value }
    }

    // MARK: - State Observation

    /// Publishes changes to the specified state property.
    ///
    /// Use this to observe changes for a specific audio state key path.
    func publisher<V: Equatable>(
        _ keyPath: KeyPath<Namespace.State, V>
    ) -> AnyPublisher<V, Never> {
        stateSubject
            .map { $0[keyPath: keyPath] }
            .eraseToAnyPublisher()
    }

    // MARK: - Action Dispatch

    func dispatchSync(
        _ action: Namespace.Action,
        delayBefore: TimeInterval? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }

            try await executor.run(
                identifier: identifier,
                state: state,
                action: action,
                delayBefore: delayBefore,
                reducers: reducers,
                middleware: middleware,
                logger: logger,
                subject: stateSubject,
                file: file,
                function: function,
                line: line
            )
        }
    }

    func dispatch(
        _ action: Namespace.Action,
        delayBefore: TimeInterval? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            do {
                try await executor.run(
                    identifier: identifier,
                    state: state,
                    action: action,
                    delayBefore: delayBefore,
                    reducers: reducers,
                    middleware: middleware,
                    logger: logger,
                    subject: stateSubject,
                    file: file,
                    function: function,
                    line: line
                )
            } catch {
                /* No-op as the error is being logged inside the executor. */
            }
        }
    }
}
