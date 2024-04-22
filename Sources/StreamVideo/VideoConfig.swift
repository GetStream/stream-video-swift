//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]

    /// The noiseCancellationFilter that StreamVideo will use to when call noiseCancellation settings
    /// require automatic handling (e.g. when the mode is set to `autoOn`).
    public let noiseCancellationFilter: AudioFilter?

    /// The audio processing module that handles the audio streams provided by WebRTC.
    public let audioProcessingModule: AudioProcessingModule
        
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    ///   - noiseCancellationFilter: An ``AudioFilter`` object representing the
    ///   noiseCancellationFilter, that the SDK will use whenever noiseCancellation handling requires
    ///   automatic actions (e.g. when the NoiseCancellationSettings.mode is set to `autoOn`).
    ///   - audioProcessingModule: Provide your own audio processing or fallback to the default one..
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoFilters: [VideoFilter] = [],
        noiseCancellationFilter: AudioFilter? = nil,
        audioProcessingModule: AudioProcessingModule = StreamAudioFilterProcessingModule()
    ) {
        self.videoFilters = videoFilters
        self.noiseCancellationFilter = noiseCancellationFilter
        self.audioProcessingModule = audioProcessingModule
    }
}

public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {
    var activeAudioFilterId: String? { get }

    func setAudioFilter(_ filter: AudioFilter?)
}
