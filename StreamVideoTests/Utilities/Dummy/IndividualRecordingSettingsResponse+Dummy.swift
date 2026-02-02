//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension IndividualRecordingSettingsResponse {
    static func dummy(
        mode: IndividualRecordingSettingsResponseMode = .available
    ) -> IndividualRecordingSettingsResponse {
        .init(mode: mode)
    }
}
