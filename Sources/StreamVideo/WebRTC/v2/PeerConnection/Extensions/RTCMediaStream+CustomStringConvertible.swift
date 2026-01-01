//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCMediaStream {
    /// Provides a detailed string representation of the RTCMediaStream.
    ///
    /// This description includes:
    /// - The stream ID
    /// - The number of audio and video tracks
    /// - Details of each track (audio and video) including their track IDs
    override public var description: String {
        let audioTracksInfo = "Audio Tracks: \(audioTracks.count)"
        let videoTracksInfo = "Video Tracks: \(videoTracks.count)"
        let trackDetails = audioTracks.map { "Audio: \($0.trackId)" } +
            videoTracks.map { "Video: \($0.trackId)" }

        return """
        RTCMediaStream:
        - StreamId: \(streamId)
        - \(audioTracksInfo)
        - \(videoTracksInfo)
        - Tracks:
          \(trackDetails.joined(separator: "\n  "))
        """
    }
}
