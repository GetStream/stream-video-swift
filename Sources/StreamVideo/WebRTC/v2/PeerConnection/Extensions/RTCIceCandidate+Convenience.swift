//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCIceCandidate {
    /// Initializes an RTCIceCandidate from a Stream_Video_Sfu_Models_ICETrickle.
    ///
    /// - Parameter source: The ICE trickle model to convert.
    /// - Throws: ClientError.Unexpected if data conversion or parsing fails.
    /// - Note: Assumes the 'candidate' field is in the JSON data.
    convenience init(_ source: Stream_Video_Sfu_Models_ICETrickle) throws {
        guard let data = source.iceCandidate.data(
            using: .utf8,
            allowLossyConversion: false
        ) else {
            throw ClientError.Unexpected()
        }
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: .mutableContainers
        ) as? [String: Any], let sdp = json["candidate"] as? String else {
            throw ClientError.Unexpected()
        }

        self.init(
            sdp: sdp,
            sdpMLineIndex: 0,
            sdpMid: nil
        )
    }
}
