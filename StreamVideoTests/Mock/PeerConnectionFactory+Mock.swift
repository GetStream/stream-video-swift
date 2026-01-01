//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

private nonisolated(unsafe) var _pc: RTCPeerConnection?

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

    func mockMediaStream(streamID: String = UUID().uuidString) -> RTCMediaStream {
        factory.mediaStream(withStreamId: streamID)
    }

    func mockTransceiver(
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        audioOptions: PublishOptions.AudioPublishOptions
    ) throws -> RTCRtpTransceiver {
        if _pc == nil {
            _pc = try makePeerConnection(
                configuration: .init(),
                constraints: .defaultConstraints,
                delegate: nil
            )
        }

        return _pc!.addTransceiver(
            of: .audio,
            init: RTCRtpTransceiverInit(
                direction: direction,
                streamIds: streamIds,
                audioOptions: audioOptions
            )
        )!
    }

    func mockTransceiver(
        of trackType: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        videoOptions: PublishOptions.VideoPublishOptions
    ) throws -> RTCRtpTransceiver {
        if _pc == nil {
            _pc = try makePeerConnection(
                configuration: .init(),
                constraints: .defaultConstraints,
                delegate: nil
            )
        }

        return _pc!.addTransceiver(
            of: .video,
            init: RTCRtpTransceiverInit(
                trackType: trackType,
                direction: direction,
                streamIds: streamIds,
                videoOptions: videoOptions
            )
        )!
    }
}
