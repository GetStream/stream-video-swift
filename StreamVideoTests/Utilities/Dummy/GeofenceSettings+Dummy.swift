//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension GeofenceSettings {
    static func dummy(
        names: [String] = []
    ) -> GeofenceSettings {
        .init(names: names)
    }
}
