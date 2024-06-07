//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension LimitsSettingsResponse {
    static func dummy(
        maxDurationSeconds: Int? = nil,
        maxParticipants: Int? = nil
    ) -> LimitsSettingsResponse {
        .init(
            maxDurationSeconds: maxDurationSeconds,
            maxParticipants: maxParticipants
        )
    }
}
