//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A protocol defining the interface for media adapters in a call.
protocol MediaAdapting {

    /// A subject for publishing track events.
    var subject: PassthroughSubject<TrackEvent, Never> { get }

    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo]

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

    func didUpdatePublishOptions(_ publishOptions: PublishOptions) async throws
}
