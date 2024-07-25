//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpTransceiverInit {
    convenience init(
        trackType: TrackType,
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        codecs: [VideoCodec]
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds
        sendEncodings = {
            guard trackType == .screenShare else {
                return codecs
            }
            return codecs + [.screenshare]
        }().map { codec in
            let encodingParam = RTCRtpEncodingParameters()
            encodingParam.rid = codec.quality
            encodingParam.maxBitrateBps = (codec.maxBitrate) as NSNumber
            if let scaleDownFactor = codec.scaleDownFactor {
                encodingParam.scaleResolutionDownBy = (scaleDownFactor) as NSNumber
            }
            if trackType == .screenShare {
                encodingParam.isActive = true
            }
            return encodingParam
        }
    }
}
