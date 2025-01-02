//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

private var _pc: RTCPeerConnection?

extension PeerConnectionFactory {
    static func mock(
        _ audioProcessingModule: AudioProcessingModule = MockAudioProcessingModule()
    ) -> PeerConnectionFactory {
        .build(
            audioProcessingModule: audioProcessingModule
        )
    }

    func mockAudioTrack() -> RTCAudioTrack {
        makeAudioTrack(source: makeAudioSource(.defaultConstraints))
    }

    func mockVideoTrack(forScreenShare: Bool) -> RTCVideoTrack {
        makeVideoTrack(source: makeVideoSource(forScreenShare: forScreenShare))
    }
}
