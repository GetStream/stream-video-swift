//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    /// Middleware that monitors and responds to audio session interruptions.
    ///
    /// This middleware listens for audio interruptions (such as incoming
    /// phone calls, alarms, or other apps taking audio focus) and updates
    /// the recording state accordingly.
    ///
    /// ## Interruption Handling
    ///
    /// When an interruption occurs:
    /// 1. The middleware receives the interruption notification
    /// 2. It dispatches `.setIsInterrupted(true)` to pause recording
    /// 3. When the interruption ends, it dispatches `.setIsInterrupted(false)`
    /// 4. Recording automatically resumes if it should be active
    final class InterruptionMiddleware: Middleware<CallAudioRecording> {
        /// The audio store for monitoring interruption state.
        @Injected(\.audioStore) private var audioStore

        /// Subscription to monitor audio interruption state changes.
        private var cancellable: AnyCancellable?

        /// Initializes the middleware and sets up interruption monitoring.
        override init() {
            super.init()

            // Forward interruption state changes to the store
            cancellable = audioStore
                .publisher(\.isInterrupted)
                .sink { [weak self] isInterrupted in
                    // Update the store's interruption state
                    self?.dispatcher?(.setIsInterrupted(isInterrupted))
                }
        }
    }
}
