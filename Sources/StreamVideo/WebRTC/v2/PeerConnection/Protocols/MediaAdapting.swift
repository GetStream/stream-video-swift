//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

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
