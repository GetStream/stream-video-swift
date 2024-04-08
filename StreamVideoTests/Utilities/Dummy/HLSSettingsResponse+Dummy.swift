//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension HLSSettingsResponse {
    static func dummy(
        autoOn: Bool = false,
        enabled: Bool = false,
        qualityTracks: [String] = []
    ) -> HLSSettingsResponse {
        .init(autoOn: autoOn, enabled: enabled, qualityTracks: qualityTracks)
    }
}
