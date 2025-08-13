//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallAudioRecordingReducer: AnyObject {

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
        state: CallAudioRecordingStore.State,
        action: CallAudioRecordingAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> CallAudioRecordingStore.State
}
