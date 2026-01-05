//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Actions that drive the audio processing store. These mirror key lifecycle
/// moments from WebRTC and user intent such as selecting an `AudioFilter`.

extension AudioProcessingStore.Namespace {

    enum StoreAction: StoreActionBoxProtocol, Sendable {
        /// Start observing processing events and wire middleware.
        case load
        /// Record the initialized sample rate and channel count.
        case setInitializedConfiguration(sampleRate: Int, channels: Int)
        /// Set or clear the active `AudioFilter`.
        case setAudioFilter(AudioFilter?)
        /// Update the current number of captured channels from incoming buffers.
        case setNumberOfCaptureChannels(Int)
        /// Tear down processing state when WebRTC releases resources.
        case release
    }
}
