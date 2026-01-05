//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension Stream_Video_Sfu_Models_Codec {
    static func dummy(
        name: String = String(),
        clockRate: UInt32 = 0,
        encodingParameters: String = String(),
        fmtp: String = String()
    ) -> Stream_Video_Sfu_Models_Codec {
        var result = Stream_Video_Sfu_Models_Codec()
        result.name = name
        result.clockRate = clockRate
        result.encodingParameters = encodingParameters
        result.fmtp = fmtp
        return result
    }
}
