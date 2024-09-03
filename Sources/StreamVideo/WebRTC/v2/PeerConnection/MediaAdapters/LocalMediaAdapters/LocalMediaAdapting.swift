//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

protocol LocalMediaAdapting {

    var subject: PassthroughSubject<TrackEvent, Never> { get }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws

    func publish()

    func unpublish()

    func didUpdateCallSettings(_ settings: CallSettings) async throws
}
