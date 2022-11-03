//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    public let persitingSocketConnection: Bool
    public let joinVideoCallInstantly: Bool
    public let ringingTimeout: TimeInterval
    public let playSounds: Bool
    public let videoEnabled: Bool
    
    public init(
        videoEnabled: Bool = true,
        persitingSocketConnection: Bool = true,
        joinVideoCallInstantly: Bool = false,
        ringingTimeout: TimeInterval = 15,
        playSounds: Bool = true
    ) {
        self.persitingSocketConnection = persitingSocketConnection
        self.joinVideoCallInstantly = joinVideoCallInstantly
        self.ringingTimeout = ringingTimeout
        self.playSounds = true
        self.videoEnabled = videoEnabled
    }
}
