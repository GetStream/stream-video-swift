//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore {

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
