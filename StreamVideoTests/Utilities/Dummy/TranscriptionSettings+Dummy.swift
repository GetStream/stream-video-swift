//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension TranscriptionSettings {
    static func dummy(
        closedCaptionMode: ClosedCaptionMode = .available,
        mode: Mode = .available
    ) -> TranscriptionSettings {
        .init(
            closedCaptionMode: closedCaptionMode,
            language: .auto,
            mode: mode
        )
    }
}
