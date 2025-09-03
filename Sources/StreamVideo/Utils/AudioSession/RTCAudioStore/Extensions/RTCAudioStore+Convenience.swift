//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore {

    func restartAudioSession(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        dispatch(
            [
                .audioSession(.isActive(false)),
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
                .audioSession(.isActive(true))
            ]
        )
    }
}
