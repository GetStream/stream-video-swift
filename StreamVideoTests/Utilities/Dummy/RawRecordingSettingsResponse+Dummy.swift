//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension RawRecordingSettingsResponse {
    static func dummy(
        mode: RawRecordingSettingsResponseMode = .available
    ) -> RawRecordingSettingsResponse {
        .init(mode: mode)
    }
}
