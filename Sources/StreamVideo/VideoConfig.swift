//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    public let persitingSocketConnection: Bool
    public let joinVideoCallInstantly: Bool
    public let ringingTimeout: TimeInterval
    public let playSounds: Bool
    public let videoEnabled: Bool
    public let videoFilters: [VideoFilter]
    
    public init(
        videoEnabled: Bool = true,
        persitingSocketConnection: Bool = true,
        joinVideoCallInstantly: Bool = false,
        ringingTimeout: TimeInterval = 15,
        playSounds: Bool = true,
        videoFilters: [VideoFilter] = []
    ) {
        self.persitingSocketConnection = persitingSocketConnection
        self.joinVideoCallInstantly = joinVideoCallInstantly
        self.ringingTimeout = ringingTimeout
        self.playSounds = true
        self.videoEnabled = videoEnabled
        self.videoFilters = videoFilters
    }
}
