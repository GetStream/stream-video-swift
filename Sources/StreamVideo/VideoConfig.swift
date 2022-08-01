//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoConfig {
    var persitingSocketConnection: Bool
    
    public init(persitingSocketConnection: Bool = true) {
        self.persitingSocketConnection = persitingSocketConnection
    }
}
