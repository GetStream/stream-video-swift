//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

/// A protocol defining the interface for media adapters in a call.
protocol MediaAdapting {

    /// A subject for publishing track events.
    var subject: PassthroughSubject<TrackEvent, Never> { get }

    /// The local media track managed by this adapter, if any.
    var localTrack: RTCMediaStreamTrack? { get }

    /// The mid (Media Stream Identification) of the local track, if available.
    var mid: String? { get }

    /// Sets up the media adapter with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the media.
    ///   - ownCapabilities: The capabilities of the local participant.
    /// - Throws: An error if the setup process fails.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws

    /// Updates the media adapter based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    /// - Throws: An error if the update process fails.
    func didUpdateCallSettings(_ settings: CallSettings) async throws
}
