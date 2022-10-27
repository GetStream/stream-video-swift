//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig: Sendable {
    let persitingSocketConnection: Bool
    let joinVideoCallInstantly: Bool
    let ringingTimeout: TimeInterval
    
    public init(
        persitingSocketConnection: Bool = true,
        joinVideoCallInstantly: Bool = true,
        ringingTimeout: TimeInterval = 15
    ) {
        self.persitingSocketConnection = persitingSocketConnection
        self.joinVideoCallInstantly = joinVideoCallInstantly
        self.ringingTimeout = ringingTimeout
    }
}
