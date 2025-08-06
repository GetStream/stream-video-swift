//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A reducer that manages audio session state changes triggered by CallKit.
///
/// `CallKitAudioSessionReducer` implements the `RTCAudioStoreReducer` protocol
/// and is responsible for updating the audio state in response to CallKit-related
/// actions, such as audio session activation or deactivation. This allows for
/// proper coordination of the WebRTC audio session lifecycle when the system
/// audio session is managed externally by CallKit.
final class CallKitAudioSessionReducer: RTCAudioStoreReducer {

    /// The underlying WebRTC audio session that is managed by this reducer.
    private let source: RTCAudioSession

    /// Creates a new reducer for handling CallKit-related audio session changes.
    ///
    /// - Parameter source: The `RTCAudioSession` instance to manage. Defaults to
    ///   the shared singleton instance.
    init(source: RTCAudioSession = .sharedInstance()) {
        self.source = source
    }

    // MARK: - RTCAudioStoreReducer

    /// Updates the audio session state based on a CallKit-related action.
    ///
    /// This method responds to `.callKit` actions from the audio store, updating
    /// the state to reflect changes triggered by CallKit, such as activating or
    /// deactivating the audio session. The reducer delegates the activation or
    /// deactivation to the underlying `RTCAudioSession`.
    ///
    /// - Parameters:
    ///   - state: The current audio session state.
    ///   - action: The audio store action to handle.
    ///   - file: The file from which the action originated (used for logging).
    ///   - function: The function from which the action originated (used for logging).
    ///   - line: The line number from which the action originated (used for logging).
    /// - Returns: The updated audio session state after processing the action.
    func reduce(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> RTCAudioStore.State {
        guard
            case let .callKit(action) = action
        else {
            return state
        }

        var updatedState = state

        switch action {
        case let .activate(audioSession):
            source.audioSessionDidActivate(audioSession)
            updatedState.isActive = source.isActive

        case let .deactivate(audioSession):
            source.audioSessionDidDeactivate(audioSession)
            updatedState.isActive = source.isActive
        }

        return updatedState
    }
}
