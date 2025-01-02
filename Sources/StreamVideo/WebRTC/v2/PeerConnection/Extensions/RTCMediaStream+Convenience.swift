//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Constant representing the identifier suffix for screen share tracks.
private let screenShareTrackType = "TRACK_TYPE_SCREEN_SHARE"

/// Constant representing the identifier suffix for video tracks.
private let videoTrackType = "TRACK_TYPE_VIDEO"

/// Constant representing the identifier suffix for audio tracks.
private let audioTrackType = "TRACK_TYPE_AUDIO"

/// Extension to add utility properties to RTCMediaStream.
extension RTCMediaStream {

    /// Determines the type of track based on the stream's identifier.
    var trackType: TrackType {
        if streamId.hasSuffix(screenShareTrackType) {
            return .screenshare
        } else if streamId.hasSuffix(videoTrackType) {
            return .video
        } else if streamId.hasSuffix(audioTrackType) {
            return .audio
        } else {
            return .unknown
        }
    }

    /// Extracts the track identifier from the stream's identifier.
    ///
    /// This property assumes that the track ID is the part of the stream ID
    /// before the first colon (:). If no colon is found, it returns the entire stream ID.
    var trackId: String {
        streamId.components(separatedBy: ":").first ?? streamId
    }
}
