//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCRtpReceiver {
    /// Provides a detailed string representation of the RTCRtpReceiver.
    ///
    /// This description includes:
    /// - Information about the associated track (if any)
    /// - Details of the RTP parameters including encodings and header extensions
    /// - The media type of the receiver
    override public var description: String {
        let trackInfo = track.map { "Track: \($0.kind) (\($0.trackId))" } ?? "No track"
        let parameterInfo =
            """
            Parameters:
              - Encodings: \(parameters.encodings.count)
              - HeaderExtensions: \(parameters.headerExtensions.count)
              - RTCP: \(parameters.rtcp)
            """

        return """
        RTCRtpReceiver:
        - \(trackInfo)
        - \(parameterInfo)
        - MediaType: \(track?.kind ?? "n/a")
        """
    }
}
