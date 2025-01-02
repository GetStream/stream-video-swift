//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpTransceiverInit {
    /// Convenience initializer for creating an `RTCRtpTransceiverInit` with specific parameters.
    ///
    /// This initializer provides a more Swift-friendly way to create an `RTCRtpTransceiverInit` object,
    /// allowing you to specify the track type, direction, stream IDs, and optional video codecs.
    ///
    /// - Parameters:
    ///   - trackType: The type of track (e.g., audio, video, or screenshare).
    ///   - direction: The desired direction for the transceiver (e.g., sendRecv, sendOnly, recvOnly).
    ///   - streamIds: An array of stream IDs associated with this transceiver.
    ///   - codecs: An optional array of video codecs to be used. If provided, these will be used to create RTP encoding parameters.
    ///
    /// - Note: If the track type is screenshare, all send encodings will be set to active.
    convenience init(
        trackType: TrackType,
        direction: RTCRtpTransceiverDirection,
        streamIds: [String],
        layers: [VideoLayer]? = nil,
        preferredVideoCodec: VideoCodec? = nil
    ) {
        self.init()
        self.direction = direction
        self.streamIds = streamIds
        if let layers {
            var sendEncodings = layers
                .map { RTCRtpEncodingParameters($0, preferredVideoCodec: preferredVideoCodec) }

            if preferredVideoCodec?.isSVC == true {
                sendEncodings = sendEncodings
                    .filter { $0.rid == "f" }
                sendEncodings.first?.rid = "q"
                self.sendEncodings = sendEncodings
            } else {
                self.sendEncodings = sendEncodings
            }
        }
        
        if trackType == .screenshare {
            sendEncodings.forEach { $0.isActive = true }
        }
    }
}
