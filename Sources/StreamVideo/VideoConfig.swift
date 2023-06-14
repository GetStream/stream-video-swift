//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]
        
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoFilters: [VideoFilter] = []
    ) {
        self.videoFilters = videoFilters
    }
}
