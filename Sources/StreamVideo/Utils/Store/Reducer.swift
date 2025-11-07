//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Base class for store reducers that process actions to produce new state.
///
/// Reducers are pure functions that take the current state and an action,
/// and return a new state. They form the core of the state management
/// system, ensuring predictable state updates.
///
/// ## Principles
///
/// Reducers must follow these principles:
/// 1. **Pure Functions**: Given the same input, always return the same output
/// 2. **Immutability**: Never modify the existing state, always return new
/// 3. **No Side Effects**: Don't perform API calls, timers, or other effects
/// 4. **Synchronous**: Return the new state immediately
///
/// ## Example Implementation
///
/// ```swift
/// class CounterReducer: Reducer<CounterNamespace> {
///     override func reduce(
///         state: State,
///         action: Action,
///         file: StaticString,
///         function: StaticString,
///         line: UInt
///     ) throws -> State {
///         var newState = state
///
///         switch action {
///         case .increment:
///             newState.count += 1
///         case .decrement:
///             newState.count -= 1
///         case let .set(value):
///             newState.count = value
///         }
///
///         return newState
///     }
/// }
/// ```
///
/// ## Composition
///
/// Multiple reducers can be composed to handle different parts of the
/// state. They are executed in sequence, with each reducer receiving the
/// state produced by the previous one.
class Reducer<Namespace: StoreNamespace>: @unchecked Sendable {
    /// Closure for dispatching new actions to the store.
    ///
    /// Use this to trigger additional actions in response to the current
    /// action. The dispatcher is automatically set when the middleware is
    /// added to a store.
    ///
    /// - Warning: Avoid creating infinite loops by dispatching actions
    ///   that trigger the same middleware repeatedly.
    var dispatcher: Store<Namespace>.Dispatcher?

    /// Processes an action to produce a new state.
    ///
    /// Override this method to implement state transformation logic. The
    /// default implementation returns the state unchanged.
    ///
    /// - Parameters:
    ///   - state: The current state before the action.
    ///   - action: The action to process.
    ///   - file: Source file where the action was dispatched.
    ///   - function: Function name where the action was dispatched.
    ///   - line: Line number where the action was dispatched.
    ///
    /// - Returns: The new state after processing the action.
    ///
    /// - Throws: An error if the action cannot be processed. Throwing will
    ///   prevent the state update and log the error.
    ///
    /// - Important: This method must be a pure function. Do not perform
    ///   side effects or modify the input state directly.
    func reduce(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> Namespace.State {
        state
    }
}
