//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
