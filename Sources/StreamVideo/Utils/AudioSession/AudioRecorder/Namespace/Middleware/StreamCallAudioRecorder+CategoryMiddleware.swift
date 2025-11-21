//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Middleware that monitors audio session category changes.
    ///
    /// This middleware ensures recording is stopped when the audio session
    /// category changes to something incompatible with recording. Recording
    /// requires either `.playAndRecord` or `.record` category to function.
    ///
    /// ## Monitored Categories
    ///
    /// Recording continues for:
    /// - `.playAndRecord` - Allows both playback and recording
    /// - `.record` - Recording only mode
    ///
    /// Recording stops for all other categories (e.g., `.playback`,
    /// `.ambient`, `.soloAmbient`).
    final class CategoryMiddleware: Middleware<StreamCallAudioRecorder.Namespace>, @unchecked Sendable {
        /// The audio store for monitoring session category changes.
        @Injected(\.audioStore) private var audioStore

        /// Subscription to monitor audio category changes.
        private var cancellable: AnyCancellable?

        /// Initializes the middleware and sets up category monitoring.
        override init() {
            super.init()

            // Monitor for category changes that are incompatible with recording
            cancellable = audioStore
                // Observe the derived configuration so system-driven category
                // changes also stop the local recorder.
                .publisher(\.audioSessionConfiguration.category)
                .filter { $0 != .playAndRecord && $0 != .record }
                .sink { [weak self] _ in
                    // Stop recording when category becomes incompatible
                    self?.dispatcher?.dispatch(.setIsRecording(false))
                }
        }
    }
}
