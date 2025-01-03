//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension EgressRTMPResponse {
    static func dummy(
        name: String = "",
        streamKey: String = "",
        url: String = ""
    ) -> EgressRTMPResponse {
        .init(name: name, startedAt: Date(), streamKey: streamKey)
    }
}
