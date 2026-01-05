//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension Stream_Video_Sfu_Event_VideoLayerSetting {

    static func dummy(
        name: String = "",
        isActive: Bool = false,
        scalabilityMode: String = "",
        maxFramerate: UInt32 = 0,
        maxBitrate: Int32 = 0,
        scaleResolutionDownBy: Float = 0,
        codec: Stream_Video_Sfu_Models_Codec = .dummy()
    ) -> Stream_Video_Sfu_Event_VideoLayerSetting {
        var result = Stream_Video_Sfu_Event_VideoLayerSetting()
        result.name = name
        result.active = isActive
        result.scalabilityMode = scalabilityMode
        result.maxFramerate = maxFramerate
        result.maxBitrate = maxBitrate
        result.scaleResolutionDownBy = scaleResolutionDownBy
        result.codec = codec
        return result
    }
}
