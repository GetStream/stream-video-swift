//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A no-operation implementation of the `LocalMediaAdapting` protocol.
///
/// This class provides a minimal implementation where all methods perform no operations,
/// useful for testing or as a placeholder in systems where local media adaptation is not required.
final class LocalNoOpMediaAdapter: LocalMediaAdapting {

    /// A publisher that emits track events.
    ///
    /// In this no-op implementation, this subject is never used to emit events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Indicates whether the adapter is currently publishing media.
    ///
    /// Always returns `false` in this no-op implementation.
    var isPublishing: Bool { false }

    /// Initializes a new instance of the no-op media adapter.
    ///
    /// - Parameter subject: A `PassthroughSubject` that could be used to emit track events.
    init(subject: PassthroughSubject<TrackEvent, Never>) {
        self.subject = subject
    }

    /// A no-op implementation of the setup method.
    ///
    /// - Parameters:
    ///   - settings: Ignored in this implementation.
    ///   - ownCapabilities: Ignored in this implementation.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }

    /// A no-op implementation of the publish method.
    func publish() {
        /* No-op */
    }

    /// A no-op implementation of the unpublish method.
    func unpublish() {
        /* No-op */
    }

    /// A no-op implementation of the trackInfo method.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] { [] }

    /// A no-op implementation of the method to handle updated call settings.
    ///
    /// - Parameter settings: Ignored in this implementation.
    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        /* No-op */
    }

    /// A no-op implementation of the method to handle updated publish options.
    ///
    /// - Parameter settings: Ignored in this implementation.
    func didUpdatePublishOptions(_ publishOptions: PublishOptions) async throws {
        /* No-op */
    }
}
