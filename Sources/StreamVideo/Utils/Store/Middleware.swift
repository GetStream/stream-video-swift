//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

/// Base class for store middleware that intercepts actions for side effects.
///
/// Middleware sits between action dispatch and state reduction, allowing you
/// to:
/// - Perform asynchronous operations
/// - Dispatch additional actions
/// - Access external services
/// - Transform or filter actions
/// - Log or monitor state changes
///
/// ## Architecture
///
/// Middleware receives actions before reducers process them. They can:
/// 1. Perform side effects (API calls, timers, etc.)
/// 2. Dispatch new actions via the `dispatcher`
/// 3. Access current state via the `state` property
///
/// ## Example Implementation
///
/// ```swift
/// class LoggingMiddleware: Middleware<MyNamespace> {
///     override func apply(
///         state: State,
///         action: Action,
///         file: StaticString,
///         function: StaticString,
///         line: UInt
///     ) {
///         print("Action: \\(action) from \\(function)")
///
///         // Dispatch follow-up action if needed
///         dispatcher?(.someOtherAction)
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// Middleware should be thread-safe as they may be called from different
/// contexts. Use appropriate synchronization when accessing shared state.
class Middleware<Namespace: StoreNamespace>: @unchecked Sendable {
    /// Closure for dispatching new actions to the store.
    ///
    /// Use this to trigger additional actions in response to the current
    /// action. The dispatcher is automatically set when the middleware is
    /// added to a store.
    ///
    /// - Warning: Avoid creating infinite loops by dispatching actions
    ///   that trigger the same middleware repeatedly.
    var dispatcher: Store<Namespace>.Dispatcher?

    /// Closure for accessing the current store state.
    ///
    /// This provider is automatically set when the middleware is added to
    /// a store. It returns the current state at the time of access.
    var stateProvider: (() -> Namespace.State?)?

    /// The current store state, if available.
    ///
    /// Returns `nil` if the middleware hasn't been added to a store yet.
    /// Use this property to make decisions based on the current state.
    var state: Namespace.State? { stateProvider?() }

    /// Processes an action before it reaches the reducers.
    ///
    /// Override this method to implement middleware logic. The default
    /// implementation does nothing.
    ///
    /// - Parameters:
    ///   - state: The current state when the action was dispatched.
    ///   - action: The action being processed.
    ///   - file: Source file where the action was dispatched.
    ///   - function: Function name where the action was dispatched.
    ///   - line: Line number where the action was dispatched.
    ///
    /// - Note: This method is called synchronously, but you can trigger
    ///   asynchronous work and dispatch actions later via `dispatcher`.
    func apply(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {}
}
