//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]
    
    /// Custom audio processing module.
    public let audioProcessingModule: AudioProcessingModule?
        
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    ///   - audioProcessingModule: Option to provide your own audio processing.
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoFilters: [VideoFilter] = [],
        audioProcessingModule: AudioProcessingModule? = nil
    ) {
        self.videoFilters = videoFilters
        self.audioProcessingModule = audioProcessingModule
    }
}

public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {}
