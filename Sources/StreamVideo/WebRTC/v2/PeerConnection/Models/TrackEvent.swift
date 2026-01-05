//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// An enumeration representing events related to media tracks in a call.
enum TrackEvent {
    /// Indicates that a new track has been added to the call.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the track.
    ///   - trackType: The type of the track (e.g., audio, video, screenshare).
    ///   - track: The actual media track that was added.
    case added(
        id: String,
        trackType: TrackType,
        track: RTCMediaStreamTrack
    )

    /// Indicates that a track has been removed from the call.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the removed track.
    ///   - trackType: The type of the track that was removed.
    ///   - track: The actual media track that was removed.
    case removed(
        id: String,
        trackType: TrackType,
        track: RTCMediaStreamTrack
    )
}
