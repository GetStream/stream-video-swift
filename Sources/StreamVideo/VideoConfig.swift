//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig {
    var persitingSocketConnection: Bool
    var joinVideoCallInstantly: Bool
    
    public init(
        persitingSocketConnection: Bool = true,
        joinVideoCallInstantly: Bool = false
    ) {
        self.persitingSocketConnection = persitingSocketConnection
        self.joinVideoCallInstantly = joinVideoCallInstantly
    }
}
