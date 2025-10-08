//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public final class VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]

    /// The noiseCancellationFilter that StreamVideo will use when call noiseCancellation settings
    /// require automatic handling (e.g. when the mode is set to `autoOn`).
    public let noiseCancellationFilter: NoiseCancellationFilter?

    /// The audio processing module that handles the audio streams provided by WebRTC.
    /// Lazily initialized to avoid requesting microphone permission until actually needed.
    public lazy var audioProcessingModule: AudioProcessingModule = {
        _customAudioProcessingModule ?? InjectedValues[\.audioFilterProcessingModule]
    }()

    private let _customAudioProcessingModule: AudioProcessingModule?

    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    ///   - noiseCancellationFilter: An ``NoiseCancellationFilter`` object representing the
    ///   noiseCancellationFilter, that the SDK will use whenever noiseCancellation handling requires
    ///   automatic actions (e.g. when the NoiseCancellationSettings.mode is set to `autoOn`).
    ///   - audioProcessingModule: Provide your own audio processing or fallback to the default one..
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoFilters: [VideoFilter] = [],
        noiseCancellationFilter: NoiseCancellationFilter? = nil,
        audioProcessingModule: AudioProcessingModule? = nil
    ) {
        self.videoFilters = videoFilters
        self.noiseCancellationFilter = noiseCancellationFilter
        self._customAudioProcessingModule = audioProcessingModule
    }
}
