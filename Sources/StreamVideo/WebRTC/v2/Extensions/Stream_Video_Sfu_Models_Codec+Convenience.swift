//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension Stream_Video_Sfu_Models_Codec {

    init(_ source: RTCRtpCodecCapability) {
        name = source.name
        fmtp = source.fmtp
        clockRate = source.clockRate?.uint32Value ?? 0
        payloadType = source.preferredPayloadType?.uint32Value ?? 0
    }
}
