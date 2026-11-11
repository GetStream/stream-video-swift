//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallIngressResponse {
    static func dummy(
        rtmp: RTMPIngress = RTMPIngress.dummy()
    ) -> CallIngressResponse {
        .init(rtmp: rtmp, srt: .init(address: ""), whip: .init(address: ""))
    }
}
