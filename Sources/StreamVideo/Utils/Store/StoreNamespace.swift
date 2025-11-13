//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Protocol defining the configuration for a store namespace.
///
/// A store namespace encapsulates all the components needed to create a
/// fully functional store: state, actions, reducers, middleware, logging,
/// and execution. It serves as a factory for creating configured store
/// instances.
///
/// ## Implementation
///
/// Conform to this protocol to define a new store:
///
/// ```swift
/// enum MyFeature: StoreNamespace {
///     typealias State = MyFeatureState
///     typealias Action = MyFeatureAction
///
///     static let identifier = "my.feature.store"
///
///     static func reducers() -> [Reducer<Self>] {
///         [MyFeatureReducer()]
///     }
///
///     static func middleware() -> [Middleware<Self>] {
///         [APIMiddleware(), LoggingMiddleware()]
///     }
/// }
/// ```
///
/// ## Usage
///
/// Create a store instance using the namespace:
///
/// ```swift
/// let store = MyFeature.store(initialState: .default)
/// ```
protocol StoreNamespace: Sendable {
    /// The state type managed by this store.
    ///
    /// Must be `Equatable` to enable change detection for publishers.
    associatedtype State: Equatable
    
    /// The action type that can be dispatched to this store.
    ///
    /// Must be `Sendable` to support concurrent dispatch from multiple
    /// contexts.
    associatedtype Action: Sendable, StoreActionBoxProtocol

    /// Unique identifier for this store namespace.
    ///
    /// Used for logging and debugging. Should be a reverse-DNS style
    /// identifier like "com.example.feature.store".
    static var identifier: String { get }

    /// Creates the reducers for processing actions.
    ///
    /// Reducers are executed in the order returned, with each receiving
    /// the state produced by the previous reducer.
    ///
    /// - Returns: Array of reducers for this store.
    static func reducers() -> [Reducer<Self>]

    /// Creates the middleware for handling side effects.
    ///
    /// Middleware are notified of actions before reducers process them,
    /// allowing for side effects, async operations, and action
    /// transformation.
    ///
    /// - Returns: Array of middleware for this store.
    static func middleware() -> [Middleware<Self>]

    static func effects() -> Set<StoreEffect<Self>>

    /// Creates the logger for this store.
    ///
    /// Override to provide custom logging behavior.
    ///
    /// - Returns: A logger instance for this store.
    static func logger() -> StoreLogger<Self>

    /// Creates the executor for processing actions.
    ///
    /// The executor coordinates the action processing pipeline. Override
    /// to customize execution behavior.
    ///
    /// - Returns: An executor instance for this store.
    static func executor() -> StoreExecutor<Self>

    /// Creates the coordinator for evaluating actions before execution.
    ///
    /// Override to provide custom logic that skips redundant actions.
    ///
    /// - Returns: A coordinator instance for this store.
    static func coordinator() -> StoreCoordinator<Self>

    /// Creates a configured store instance.
    ///
    /// This method assembles all components into a functioning store.
    /// The default implementation should work for most cases.
    ///
    /// - Parameters:
    ///   - initialState: The initial state for the store.
    ///   - reducers: Reducers used to transform state.
    ///   - middleware: Middleware that handle side effects.
    ///   - logger: Logger responsible for diagnostics.
    ///   - executor: Executor that runs the action pipeline.
    ///   - coordinator: Coordinator that can skip redundant actions.
    /// - Returns: A fully configured store instance.
    static func store(
        initialState: State,
        reducers: [Reducer<Self>],
        middleware: [Middleware<Self>],
        effects: Set<StoreEffect<Self>>,
        logger: StoreLogger<Self>,
        executor: StoreExecutor<Self>,
        coordinator: StoreCoordinator<Self>
    ) -> Store<Self>
}

// MARK: - Default Implementations

extension StoreNamespace {

    /// Default implementation returns empty array.
    static func reducers() -> [Reducer<Self>] { [] }

    /// Default implementation returns empty array.
    static func middleware() -> [Middleware<Self>] { [] }

    static func effects() -> Set<StoreEffect<Self>> { [] }

    /// Default implementation returns basic logger.
    static func logger() -> StoreLogger<Self> { .init() }

    /// Default implementation returns basic executor.
    static func executor() -> StoreExecutor<Self> { .init() }

    /// Default implementation returns a coordinator with no skip logic.
    static func coordinator() -> StoreCoordinator<Self> { .init() }

    /// Default implementation creates a store with all components.
    ///
    /// This implementation:
    /// 1. Uses the namespace's identifier
    /// 2. Sets the provided initial state
    /// 3. Adds reducers from `reducers()`
    /// 4. Adds middleware from `middleware()`
    /// 5. Uses logger from `logger()`
    /// 6. Uses executor from `executor()`
    /// 7. Uses coordinator from `coordinator()`
    static func store(
        initialState: State,
        reducers: [Reducer<Self>] = Self.reducers(),
        middleware: [Middleware<Self>] = Self.middleware(),
        effects: Set<StoreEffect<Self>> = Self.effects(),
        logger: StoreLogger<Self> = Self.logger(),
        executor: StoreExecutor<Self> = Self.executor(),
        coordinator: StoreCoordinator<Self> = Self.coordinator()
    ) -> Store<Self> {
        .init(
            identifier: Self.identifier,
            initialState: initialState,
            reducers: reducers,
            middleware: middleware,
            effects: effects,
            logger: logger,
            executor: executor,
            coordinator: coordinator
        )
    }
}
