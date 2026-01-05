//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// State for the audio processing pipeline (sample format, channels, filters).

extension AudioProcessingStore.Namespace {

    struct StoreState: Equatable, Sendable {
        /// Sample rate reported by WebRTC at initialization time.
        var initializedSampleRate: Int
        /// Channel count reported by WebRTC at initialization time.
        var initializedChannels: Int
        /// Current number of channels observed from capture buffers.
        var numberOfCaptureChannels: Int
        /// Delegate that surfaces custom processing callbacks as events.
        var capturePostProcessingDelegate: AudioCustomProcessingModule
        /// The active effect applied to audio capture, if any.
        var audioFilter: AudioFilter?

        /// Minimal initial state; real values arrive via `.load` flow.
        static let initial = StoreState(
            initializedSampleRate: 0,
            initializedChannels: 0,
            numberOfCaptureChannels: 0,
            capturePostProcessingDelegate: .init(),
            audioFilter: nil
        )

        /// Equality optimized for UI/state updates; ignores derived fields.
        static func == (
            lhs: AudioProcessingStore.Namespace.StoreState,
            rhs: AudioProcessingStore.Namespace.StoreState
        ) -> Bool {
            lhs.numberOfCaptureChannels == rhs.numberOfCaptureChannels
                && lhs.capturePostProcessingDelegate === rhs.capturePostProcessingDelegate
                && lhs.audioFilter?.id == rhs.audioFilter?.id
        }
    }
}
