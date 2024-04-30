import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine
import StreamVideoNoiseCancellation

@MainActor
fileprivate func content() {
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
            tokenProvider: { _ in }
        )
    }
}
