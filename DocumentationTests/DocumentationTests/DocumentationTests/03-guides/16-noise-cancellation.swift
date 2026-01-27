//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoNoiseCancellation
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        let processor = NoiseCancellationProcessor()

        // Secondly you instantiate the NoiseCancellationFilter. You can use any name, but it needs to be unique compared to other AudioFilters you may be using.
        let noiseCancellationFilter = NoiseCancellationFilter(
            name: "noise-cancellation",
            initialize: processor.initialize,
            process: processor.process,
            release: processor.release
        )
    }

    container {
        // Create the NoiseCancellationFilter like the example above.

        // Then you create VideoConfig instance that includes our NoiseCancellationFilter.
        let videoConfig = VideoConfig(noiseCancellationFilter: noiseCancellationFilter)

        // Finally, you create the StreamVideo instance by passing in our videoConfig.
        let streamVideo = StreamVideo(
            apiKey: apiKey,
            user: user,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: { result in
                // Handle token refresh
            }
        )
    }

    asyncContainer {
        // Start noise cancellation
        try await call.startNoiseCancellation()

        // Stop noise cancellation
        try await call.stopNoiseCancellation()
    }

    container {
        let isNoiseCancellationActive = call.state.settings?.audio.noiseCancellation?.mode == .autoOn
    }
}
