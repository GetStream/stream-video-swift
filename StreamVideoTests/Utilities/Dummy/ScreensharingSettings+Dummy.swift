//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension ScreensharingSettings {
    static func dummy(
        accessRequestEnabled: Bool = false,
        enabled: Bool = false
    ) -> ScreensharingSettings {
        .init(accessRequestEnabled: accessRequestEnabled, enabled: enabled)
    }
}
