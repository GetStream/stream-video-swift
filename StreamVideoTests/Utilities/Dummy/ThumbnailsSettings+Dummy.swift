//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension ThumbnailsSettings {
    static func dummy(
        enabled: Bool = false
    ) -> ThumbnailsSettings {
        .init(enabled: enabled)
    }
}
