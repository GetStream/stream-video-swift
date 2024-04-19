//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]

    public let noiseCancellationFilter: AudioFilter?

    /// Custom audio processing module.
    public let audioProcessingModule: AudioProcessingModule
        
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    ///   - audioProcessingModule: Option to provide your own audio processing.
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
