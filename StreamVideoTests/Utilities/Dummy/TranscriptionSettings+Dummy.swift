//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension TranscriptionSettings {
    static func dummy(
        closedCaptionMode: String = "",
        mode: Mode = .available
    ) -> TranscriptionSettings {
        .init(
            closedCaptionMode: closedCaptionMode,
            mode: mode
        )
    }
}
