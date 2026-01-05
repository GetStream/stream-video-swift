//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension BroadcastSettingsResponse {
    static func dummy(
        enabled: Bool = false,
        hls: HLSSettingsResponse = .dummy()
    ) -> BroadcastSettingsResponse {
        .init(enabled: enabled, hls: hls, rtmp: .init(enabled: enabled, quality: "good"))
    }
}
