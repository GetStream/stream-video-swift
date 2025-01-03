//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension RecordSettingsResponse {
    static func dummy(
        audioOnly: Bool = false,
        mode: String = "",
        quality: String = ""
    ) -> RecordSettingsResponse {
        .init(audioOnly: audioOnly, mode: mode, quality: quality)
    }
}
