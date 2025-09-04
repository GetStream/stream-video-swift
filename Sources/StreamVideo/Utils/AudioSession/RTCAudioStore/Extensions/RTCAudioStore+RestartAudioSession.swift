//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore {

    /// Actions used to restart the audio session in a safe order.
    ///
    /// Sequence: deactivate, short delay, reapply category/mode/options,
    /// reapply output port override, short delay, then reactivate.
    private var restartAudioSessionActions: [RTCAudioStoreAction] {
        let state = self.state
        return [
            .failable(.audioSession(.setAVAudioSessionActive(false))),
            .generic(.delay(seconds: 0.2)),
            .audioSession(
                .setCategory(
                    state.category,
                    mode: state.mode,
                    options: state.options
                )
            ),
            .audioSession(
                .setOverrideOutputPort(state.overrideOutputAudioPort)
            ),
            .generic(.delay(seconds: 0.2)),
            .failable(.audioSession(.setAVAudioSessionActive(true)))
        ]
    }

    /// Restarts the audio session asynchronously using the store's current
    /// configuration.
    ///
    /// The restart sequence deactivates the session, allows a brief settle,
    /// reapplies category, mode and options, reapplies the output port
    /// override, and reactivates the session.
    ///
    /// - Parameters:
    ///   - file: Call-site file used for logging context.
    ///   - function: Call-site function used for logging context.
    ///   - line: Call-site line used for logging context.
    func restartAudioSession(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log.debug(
            "Store identifier:RTCAudioStore will restart AudioSession asynchronously.",
            subsystems: .audioSession
        )
        dispatch(
            restartAudioSessionActions,
            file: file,
            function: function,
            line: line
        )
    }

    /// Restarts the audio session and suspends until completion.
    ///
    /// Mirrors ``restartAudioSession()`` but executes synchronously and
    /// surfaces errors from the underlying audio-session operations.
    ///
    /// - Parameters:
    ///   - file: Call-site file used for logging context.
    ///   - function: Call-site function used for logging context.
    ///   - line: Call-site line used for logging context.
    /// - Throws: Errors thrown by dispatched audio-session actions.
    func restartAudioSessionSync(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        log.debug(
            "Store identifier:RTCAudioStore will restart AudioSession.",
            subsystems: .audioSession
        )
        try await dispatchAsync(
            restartAudioSessionActions,
            file: file,
            function: function,
            line: line
        )
        log.debug(
            "Store identifier:RTCAudioStore did restart AudioSession.",
            subsystems: .audioSession
        )
    }
}
