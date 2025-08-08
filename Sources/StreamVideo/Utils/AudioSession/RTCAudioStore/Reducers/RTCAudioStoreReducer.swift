//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines how to handle state changes in the RTCAudioStore.
///
/// Implementers of this protocol provide logic to process actions and produce a new state.
/// This is useful for managing audio-related state in a predictable and testable way.
protocol RTCAudioStoreReducer: AnyObject {

    /// Processes an action and returns the updated state of the RTCAudioStore.
    ///
    /// - Parameters:
    ///   - state: The current state before the action is applied.
    ///   - action: The action to be handled which may modify the state.
    ///   - file: The source file where the action was dispatched (for debugging).
    ///   - function: The function name where the action was dispatched (for debugging).
    ///   - line: The line number where the action was dispatched (for debugging).
    /// - Throws: An error if the state reduction fails.
    /// - Returns: The new state after applying the action.
    func reduce(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> RTCAudioStore.State
}
