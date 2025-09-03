//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore {

    func restartAudioSession(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        // Delays seems to be important!
        dispatch(
            [
                .audioSession(.isActive(false)),
                .generic(.delay(seconds: 0.2)),
                .audioSession(.isAudioEnabled(false)),
                .generic(.delay(seconds: 0.2)),
                .audioSession(
                    .setCategory(
                        category,
                        mode: mode,
                        options: options
                    )
                ),
                .generic(.delay(seconds: 0.2)),
                .audioSession(.isAudioEnabled(true)),
                .generic(.delay(seconds: 0.2)),
                .audioSession(.isActive(true))
            ],
            file: file,
            function: function,
            line: line
        )
    }
}
