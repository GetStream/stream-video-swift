//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]
    
    /// By default is false. Set to true if you want to listen to all the raw WS events.
    public let listenToAllEvents: Bool
    
    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoEnabled: A Boolean value indicating whether video is enabled for the call.
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        listenToAllEvents: Bool = false,
        videoFilters: [VideoFilter] = []
    ) {
        self.listenToAllEvents = listenToAllEvents
        self.videoFilters = videoFilters
    }
}
