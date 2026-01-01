//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

extension RTCMediaStreamTrack {

    static func dummy(
        kind: TrackType,
        peerConnectionFactory: PeerConnectionFactory
    ) -> RTCMediaStreamTrack {
        switch kind {
        case .audio:
            let source = peerConnectionFactory.makeAudioSource(.defaultConstraints)
            let track = peerConnectionFactory.makeAudioTrack(source: source)
            return track

        case .video:
            let source = peerConnectionFactory.makeVideoSource(forScreenShare: false)
            let track = peerConnectionFactory.makeVideoTrack(source: source)
            return track

        case .screenshare:
            let source = peerConnectionFactory.makeVideoSource(forScreenShare: true)
            let track = peerConnectionFactory.makeVideoTrack(source: source)
            return track

        default:
            assert(false)
        }
    }
}
