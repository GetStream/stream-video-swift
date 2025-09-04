//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore {

    private var restartAudioSessionActions: [RTCAudioStoreAction] {
        let state = self.state
        return [
            .audioSession(.isActive(false)),
            .audioSession(.isAudioEnabled(false)),
            .generic(.delay(seconds: 0.2)),
            .audioSession(
                .setCategory(
                    state.category,
                    mode: state.mode,
                    options: state.options
                )
            ),
            .generic(.delay(seconds: 0.2)),
            .audioSession(.isAudioEnabled(true)),
            .audioSession(.isActive(true))
        ]
    }

    func restartAudioSession(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
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
        try await dispatchAsync(
            restartAudioSessionActions,
            file: file,
            function: function,
            line: line
        )
    }
}
