//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

enum TrackEvent {
    case added(
        id: String,
        trackType: TrackType,
        track: RTCMediaStreamTrack
    )

    case removed(
        id: String,
        trackType: TrackType,
        track: RTCMediaStreamTrack
    )
}

protocol MediaAdapting {

    var subject: PassthroughSubject<TrackEvent, Never> { get }

    var localTrack: RTCMediaStreamTrack? { get }

    var mid: String? { get }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws

    func didUpdateCallSettings(_ settings: CallSettings) async throws
}
