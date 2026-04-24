//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coordinates store actions to prevent redundant state transitions.
///
/// The coordinator evaluates an action against the current state before the
/// store processes it.
/// Implementations can override ``shouldExecute(action:state:)``
/// to skip actions that would not yield a different state,
/// reducing unnecessary work along the pipeline.
class StoreCoordinator<Namespace: StoreNamespace>: @unchecked Sendable {

    /// Resolves the action that should flow through the store pipeline.
    ///
    /// The default implementation preserves the original action when
    /// ``shouldExecute(action:state:)`` returns `true` and skips it
    /// otherwise. Subclasses can override this method to unwrap or rewrite
    /// actions before middleware and reducers receive them.
    ///
    /// - Parameters:
    ///   - action: The boxed action that is about to be dispatched.
    ///   - state: The current state before the action runs.
    /// - Returns: The action to execute, or `nil` to skip execution.
    func coordinate(
        action: StoreActionBox<Namespace.Action>,
        state: Namespace.State
    ) -> StoreActionBox<Namespace.Action>? {
        shouldExecute(
            action: action.wrappedValue,
            state: state
        ) ? action : nil
    }

    /// Determines whether an action should run for the provided state snapshot.
    ///
    /// This default implementation always executes the action.
    /// Subclasses can override the method to run diffing logic or other
    /// heuristics that detect state changes and return `false` when the action
    /// can be safely skipped.
    ///
    /// - Parameters:
    ///   - action: The action that is about to be dispatched.
    ///   - state: The current state before the action runs.
    /// - Returns: `true` to process the action; `false` to skip it.
    func shouldExecute(
        action: Namespace.Action,
        state: Namespace.State
    ) -> Bool {
        true
    }
}
