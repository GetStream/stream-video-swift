//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A Redux-like store for managing application state.
///
/// The store provides a centralized, predictable state container that
/// follows unidirectional data flow principles. It coordinates actions,
/// reducers, middleware, and state updates.
///
/// ## Architecture
///
/// The store implements the following data flow:
/// 1. **Action Dispatch**: Actions describe state changes
/// 2. **Middleware Processing**: Side effects and async operations
/// 3. **Reducer Processing**: Pure state transformations
/// 4. **State Publishing**: Notify observers of changes
///
/// ## Features
///
/// - **Thread-Safe**: Actions are processed serially on a queue
/// - **Observable**: Publish state changes via Combine
/// - **Extensible**: Add/remove middleware and reducers dynamically
/// - **Debuggable**: Built-in logging and source tracking
///
/// ## Usage Example
///
/// ```swift
/// let store = MyNamespace.store(initialState: .default)
///
/// // Subscribe to state changes
/// store.publisher(\.someProperty)
///     .sink { value in
///         print("Property changed: \(value)")
///     }
///
/// // Dispatch actions
/// store.dispatch(.updateSomething(value))
/// ```
///
/// - Note: The store is marked `@unchecked Sendable` because it manages
///   its own synchronization through a serial operation queue.
final class Store<Namespace: StoreNamespace>: @unchecked Sendable {

    /// The current state of the store.
    ///
    /// This property provides synchronous access to the current state.
    /// For observing changes, use ``publisher(_:)`` instead.
    var state: Namespace.State { stateSubject.value }

    let statePublisher: AnyPublisher<Namespace.State, Never>

    /// Unique identifier for this store instance.
    private let identifier: String
    
    /// Logger for recording store operations.
    private let logger: StoreLogger<Namespace>
    
    /// Executor that processes actions through the pipeline.
    private let executor: StoreExecutor<Namespace>

    /// Coordinator that can skip redundant actions before execution.
    private let coordinator: StoreCoordinator<Namespace>

    /// Publisher that holds and emits the current state.
    private let stateSubject: CurrentValueSubject<Namespace.State, Never>
    
    /// Serial queue ensuring thread-safe action processing.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    /// Array of reducers that process actions to update state.
    private var reducers: [Reducer<Namespace>]
    
    /// Array of middleware that handle side effects.
    private var middleware: [Middleware<Namespace>]

    private var effects: Set<StoreEffect<Namespace>>

    /// Initializes a new store with the specified configuration.
    ///
    /// - Parameters:
    ///   - identifier: Unique identifier for debugging and logging.
    ///   - initialState: The initial state of the store.
    ///   - reducers: Array of reducers for processing actions.
    ///   - middleware: Array of middleware for side effects.
    ///   - logger: Logger for recording store operations.
    ///   - executor: Executor for processing the action pipeline.
    ///   - coordinator: Coordinator that validates actions before execution.
    init(
        identifier: String,
        initialState: Namespace.State,
        reducers: [Reducer<Namespace>],
        middleware: [Middleware<Namespace>],
        effects: Set<StoreEffect<Namespace>>,
        logger: StoreLogger<Namespace>,
        executor: StoreExecutor<Namespace>,
        coordinator: StoreCoordinator<Namespace>
    ) {
        self.identifier = identifier
        let stateSubject = CurrentValueSubject<Namespace.State, Never>(initialState)
        self.stateSubject = stateSubject
        self.statePublisher = stateSubject.eraseToAnyPublisher()
        self.reducers = []
        self.middleware = []
        self.effects = []
        self.logger = logger
        self.executor = executor
        self.coordinator = coordinator

        reducers.forEach { add($0) }
        middleware.forEach { add($0) }
        effects.forEach { add($0) }
    }

    // MARK: - Middleware Management

    /// Adds middleware to observe or intercept actions.
    ///
    /// Middleware are automatically connected to the store's dispatcher
    /// and state provider. Duplicate middleware (by reference) are ignored.
    ///
    /// - Parameter value: The middleware to add.
    func add<T: Middleware<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self,
                middleware.first(where: { $0 === value }) == nil
            else {
                return
            }
            middleware.append(value)
            value.dispatcher = .init(self)
            value.stateProvider = { [weak self] in self?.state }
        }
    }

    /// Removes previously added middleware.
    ///
    /// This disconnects the middleware from the store's dispatcher and
    /// state provider.
    ///
    /// - Parameter value: The middleware to remove.
    func remove<T: Middleware<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self
            else {
                return
            }

            middleware = middleware.filter { $0 !== value }
            value.dispatcher = nil
            value.stateProvider = nil
        }
    }

    // MARK: - Reducer Management

    /// Adds a reducer to process actions.
    ///
    /// Reducers are executed in the order they were added. Duplicate
    /// reducers (by reference) are ignored.
    ///
    /// - Parameter value: The reducer to add.
    func add<T: Reducer<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self,
                reducers.first(where: { $0 === value }) == nil
            else {
                return
            }
            reducers.append(value)
            value.dispatcher = .init(self)
        }
    }

    /// Removes a previously added reducer.
    ///
    /// - Parameter value: The reducer to remove.
    func remove<T: Reducer<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self
            else {
                return
            }
            reducers = reducers.filter { $0 !== value }
            value.dispatcher = nil
        }
    }

    // MARK: - Effects Management

    /// Adds an effect to respond to state changes.
    ///
    /// Effects are executed every time the store's state gets updated.
    ///
    /// - Parameter value: The effect to add.
    func add<T: StoreEffect<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self
            else {
                return
            }
            effects.insert(value)
            value.dispatcher = .init(self)
            value.set(statePublisher: statePublisher)
            value.stateProvider = { [weak self] in self?.state }
        }
    }

    /// Removes a previously added reducer.
    ///
    /// - Parameter value: The reducer to remove.
    func remove<T: StoreEffect<Namespace>>(_ value: T) {
        processingQueue.addOperation { [weak self] in
            guard
                let self
            else {
                return
            }
            effects.remove(value)
            value.dispatcher = nil
            value.set(statePublisher: nil)
            value.stateProvider = nil
        }
    }

    // MARK: - State Observation

    /// Creates a publisher for observing changes to a specific state
    /// property.
    ///
    /// The publisher only emits when the value at the key path changes,
    /// using `Equatable` conformance to detect changes.
    ///
    /// ## Example
    ///
    /// ```swift
    /// store.publisher(\.isRecording)
    ///     .sink { isRecording in
    ///         updateUI(recording: isRecording)
    ///     }
    /// ```
    ///
    /// - Parameter keyPath: The key path to the state property to observe.
    ///
    /// - Returns: A publisher that emits the property value on changes.
    func publisher<V: Equatable>(
        _ keyPath: KeyPath<Namespace.State, V>
    ) -> AnyPublisher<V, Never> {
        stateSubject
            .map { $0[keyPath: keyPath] }
            .eraseToAnyPublisher()
    }

    // MARK: - Action Dispatch

    /// Dispatches one or more actions asynchronously.
    ///
    /// This queues the provided actions for processing and returns
    /// immediately. Actions are processed serially in the order they were
    /// dispatched.
    ///
    /// - Parameters:
    ///   - actions: The actions to dispatch, optionally boxed with
    ///     ``StoreActionBox`` for custom delays.
    ///   - file: Source file (automatically captured).
    ///   - function: Function name (automatically captured).
    ///   - line: Line number (automatically captured).
    ///
    /// - Note: Errors from reducers are not thrown here. They are
    ///   captured by the returned ``StoreTask``. If you need to handle
    ///   errors, `await` ``StoreTask/result()`` on the returned task.
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Fire‑and‑forget
    /// store.dispatch(.someAction)
    ///
    /// // Debounce rapid updates (delay before processing a specific action)
    /// store.dispatch([
    ///     .delayed(.updateValue(text), delay: .init(before: 0.3))
    /// ])
    ///
    /// // Await completion and handle errors
    /// let task = store.dispatch(.performWork)
    /// do {
    ///     try await task.result()
    /// } catch {
    ///     logger.error("Action failed: \(error)")
    /// }
    /// ```
    ///
    /// - Returns: A ``StoreTask`` that can be awaited or ignored for
    ///   fire-and-forget semantics.
    @discardableResult
    func dispatch(
        _ actions: [StoreActionBox<Namespace.Action>],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        let task = StoreTask(executor: executor, coordinator: coordinator)
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }
            await task.run(
                identifier: identifier,
                state: state,
                actions: actions,
                reducers: reducers,
                middleware: middleware,
                logger: logger,
                subject: stateSubject,
                file: file,
                function: function,
                line: line
            )
        }
        return task
    }

    /// Dispatches a single boxed action asynchronously.
    ///
    /// Wraps the action in an array and forwards to
    /// ``dispatch(_:file:function:line:)``.
    ///
    /// - Returns: A ``StoreTask`` that can be awaited or ignored.
    @discardableResult
    func dispatch(
        _ action: StoreActionBox<Namespace.Action>,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        dispatch(
            [action],
            file: file,
            function: function,
            line: line
        )
    }

    /// Dispatches multiple unboxed actions asynchronously.
    ///
    /// Actions are boxed automatically before being forwarded to
    /// ``dispatch(_:file:function:line:)``.
    ///
    /// - Returns: A ``StoreTask`` that can be awaited or ignored.
    @discardableResult
    func dispatch(
        _ actions: [Namespace.Action],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        dispatch(
            actions.map(\.box),
            file: file,
            function: function,
            line: line
        )
    }

    /// Dispatches a single unboxed action asynchronously.
    ///
    /// The action is boxed automatically and forwarded to
    /// ``dispatch(_:file:function:line:)``.
    ///
    /// - Returns: A ``StoreTask`` that can be awaited or ignored.
    @discardableResult
    func dispatch(
        _ action: Namespace.Action,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        dispatch(
            [action.box],
            file: file,
            function: function,
            line: line
        )
    }
}
