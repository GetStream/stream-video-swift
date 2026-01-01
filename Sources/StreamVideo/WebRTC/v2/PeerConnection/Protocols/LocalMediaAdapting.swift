//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that defines the interface for adapting local media in a call.
protocol LocalMediaAdapting {

    /// A publisher that emits track events.
    ///
    /// This subject can be used to observe changes in local media tracks.
    var subject: PassthroughSubject<TrackEvent, Never> { get }

    /// Sets up the local media adapter with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The initial call settings to configure the adapter.
    ///   - ownCapabilities: An array of capabilities that the local participant possesses.
    ///
    /// - Throws: An error if the setup process fails.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws

    /// Starts publishing local media tracks.
    ///
    /// This method should be called when the local participant wants to share their media with others.
    func publish()

    /// Stops publishing local media tracks.
    ///
    /// This method should be called when the local participant wants to stop sharing their media.
    func unpublish()

    func trackInfo(for collectionType: RTCPeerConnectionTrackInfoCollectionType) -> [Stream_Video_Sfu_Models_TrackInfo]

    /// Updates the adapter with new call settings.
    ///
    /// - Parameter settings: The updated call settings to apply.
    ///
    /// - Throws: An error if the update process fails.
    func didUpdateCallSettings(_ settings: CallSettings) async throws

    func didUpdatePublishOptions(_ publishOptions: PublishOptions) async throws
}
