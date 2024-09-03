//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class LocalNoOpMediaAdapter: LocalMediaAdapting {

    let subject: PassthroughSubject<TrackEvent, Never>
    var isPublishing: Bool { false }

    init(subject: PassthroughSubject<TrackEvent, Never>) {
        self.subject = subject
    }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }
    
    func publish() {
        /* No-op */
    }
    
    func unpublish() {
        /* No-op */
    }

    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        /* No-op */
    }
}
