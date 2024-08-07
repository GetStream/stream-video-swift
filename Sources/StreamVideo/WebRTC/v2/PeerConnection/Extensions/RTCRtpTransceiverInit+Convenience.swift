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
        codecs: [VideoCodec]? = nil
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds
        if let codecs {
            self.sendEncodings = codecs
                .map(RTCRtpEncodingParameters.init)
        }

        if trackType == .screenshare {
            self.sendEncodings.forEach { $0.isActive = true }
        }
    }
}

extension RTCRtpEncodingParameters {

    convenience init(_ codec: VideoCodec) {
        self.init()
        self.rid = codec.quality
        self.maxBitrateBps = (codec.maxBitrate) as NSNumber
        if let scaleDownFactor = codec.scaleDownFactor {
            self.scaleResolutionDownBy = (scaleDownFactor) as NSNumber
        }
    }
}
