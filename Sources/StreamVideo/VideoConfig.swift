//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    /// A Boolean value indicating whether to play sounds during video calls.
    public let playSounds: Bool
    
    /// A Boolean value indicating whether video is enabled for the call.
    public let videoEnabled: Bool
    
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]
    
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoEnabled: A Boolean value indicating whether video is enabled for the call.
    ///   - playSounds: A Boolean value indicating whether to play sounds during video calls.
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoEnabled: Bool = true,
        playSounds: Bool = true,
        videoFilters: [VideoFilter] = []
    ) {
        self.playSounds = true
        self.videoEnabled = videoEnabled
        self.videoFilters = videoFilters
    }
}
