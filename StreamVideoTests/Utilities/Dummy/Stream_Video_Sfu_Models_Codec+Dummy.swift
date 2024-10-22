//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension Stream_Video_Sfu_Models_Codec {
    static func dummy(
        payloadType: UInt32 = 0,
        name: String = "",
        clockRate: UInt32 = 0,
        encodingParameters: String = "",
        feedbacks: [String] = []
    ) -> Stream_Video_Sfu_Models_Codec {
        var result = Stream_Video_Sfu_Models_Codec()
        result.payloadType = payloadType
        result.name = name
        result.clockRate = clockRate
        result.encodingParameters = encodingParameters
        result.feedbacks = feedbacks
        return result
    }
}
