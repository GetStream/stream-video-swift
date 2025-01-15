//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallIngressResponse {
    static func dummy(
        rtmp: RTMPIngress = RTMPIngress.dummy()
    ) -> CallIngressResponse {
        .init(rtmp: rtmp)
    }
}
