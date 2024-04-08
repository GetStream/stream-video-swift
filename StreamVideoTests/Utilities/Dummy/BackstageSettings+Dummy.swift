//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension BackstageSettings {
    static func dummy(
        enabled: Bool = false
    ) -> BackstageSettings {
        .init(enabled: enabled)
    }
}
