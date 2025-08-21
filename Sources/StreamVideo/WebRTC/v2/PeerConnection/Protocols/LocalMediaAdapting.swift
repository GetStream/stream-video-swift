//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that defines the interface for adapting local media in a call.
protocol LocalMediaAdapting {

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

    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo]

    /// Updates the adapter with new call settings.
    ///
    /// - Parameter settings: The updated call settings to apply.
    ///
    /// - Throws: An error if the update process fails.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws

    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws
}
