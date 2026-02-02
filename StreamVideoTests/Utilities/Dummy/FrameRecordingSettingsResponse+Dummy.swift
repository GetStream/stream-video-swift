//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension FrameRecordingSettingsResponse {
    static func dummy(
        captureIntervalInSeconds: Int = 10,
        mode: FrameRecordingSettingsResponseMode = .available,
        quality: String? = nil
    ) -> FrameRecordingSettingsResponse {
        .init(
            captureIntervalInSeconds: captureIntervalInSeconds,
            mode: mode,
            quality: quality
        )
    }
}
