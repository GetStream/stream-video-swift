//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

extension PeerConnectionFactory {
    static func mock(
        _ audioProcessingModule: AudioProcessingModule = MockAudioProcessingModule.shared
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
