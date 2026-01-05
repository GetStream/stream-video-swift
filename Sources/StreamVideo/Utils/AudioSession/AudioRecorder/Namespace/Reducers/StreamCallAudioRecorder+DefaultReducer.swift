//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// The default reducer for processing call audio recording actions.
    ///
    /// This reducer handles all state updates for the audio recording store.
    /// It processes each action type and returns an updated state accordingly.
    ///
    /// ## Action Processing
    ///
    /// The reducer handles the following actions:
    /// - `.setIsRecording`: Updates the active recording state
    /// - `.setIsInterrupted`: Updates the interruption state
    /// - `.setShouldRecord`: Updates the desired recording state
    /// - `.setMeter`: Updates the current audio level
    ///
    /// ## Pure Function
    ///
    /// As a reducer, this class implements a pure function that:
    /// - Takes the current state and an action as input
    /// - Returns a new state without side effects
    /// - Does not modify the original state
    final class DefaultReducer: Reducer<StreamCallAudioRecorder.Namespace>, @unchecked Sendable {
        /// Processes an action to produce a new state.
        ///
        /// This method creates a copy of the current state, applies the
        /// action's changes, and returns the updated state.
        ///
        /// - Parameters:
        ///   - state: The current state before the action.
        ///   - action: The action to process.
        ///   - file: Source file where the action was dispatched.
        ///   - function: Function name where the action was dispatched.
        ///   - line: Line number where the action was dispatched.
        ///
        /// - Returns: A new state reflecting the action's changes.
        ///
        /// - Throws: This implementation doesn't throw, but the protocol
        ///   allows for error handling in complex reducers.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
            var updatedState = state

            switch action {
            case let .setIsRecording(value):
                updatedState.isRecording = value

            case let .setIsInterrupted(value):
                updatedState.isInterrupted = value

            case let .setShouldRecord(value):
                updatedState.shouldRecord = value

            case let .setMeter(value):
                updatedState.meter = value
            }

            return updatedState
        }
    }
}
