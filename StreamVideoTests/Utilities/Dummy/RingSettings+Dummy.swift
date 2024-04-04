//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension RingSettings {
    static func dummy(
        autoCancelTimeoutMs: Int = 0,
        incomingCallTimeoutMs: Int = 0
    ) -> RingSettings {
        .init(autoCancelTimeoutMs: autoCancelTimeoutMs, incomingCallTimeoutMs: incomingCallTimeoutMs)
    }
}
