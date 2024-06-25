//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class PeerConnectionFactory {

    private let audioProcessingModule: RTCAudioProcessingModule
    private lazy var factory: RTCPeerConnectionFactory = {
        let encoderFactory = RTCVideoEncoderFactorySimulcast(
            primary: defaultEncoder,
            fallback: defaultEncoder
        )
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
            bypassVoiceProcessing: false,
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory,
            audioProcessingModule: audioProcessingModule
        )
    }()

    private lazy var defaultEncoder = RTCDefaultVideoEncoderFactory()
    private lazy var defaultDecoder = RTCDefaultVideoDecoderFactory()

    var supportedVideoCodecEncoding: [RTCVideoCodecInfo] {
        defaultEncoder.supportedCodecs()
    }
    
    var supportedVideoCodecDecoding: [RTCVideoCodecInfo] {
        defaultDecoder.supportedCodecs()
    }
    
    init(audioProcessingModule: RTCAudioProcessingModule) {
        self.audioProcessingModule = audioProcessingModule
        _ = factory
    }

    deinit {
        RTCCleanupSSL()
    }

    func makePeerConnection(
        sessionId: String,
        configuration: RTCConfiguration,
        type: PeerConnectionType,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        constraints: RTCMediaConstraints = RTCMediaConstraints.defaultConstraints,
        videoOptions: VideoOptions
    ) throws -> PeerConnection {
        let pc = try makePeerConnection(
            configuration: configuration,
            constraints: constraints,
            delegate: nil
        )
        let peerConnection = PeerConnection(
            sessionId: sessionId,
            pc: pc,
            type: type,
            signalService: signalService,
            videoOptions: videoOptions
        )
        return peerConnection
    }
    
    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource {
        factory.videoSource(forScreenCast: forScreenShare)
    }

    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
        factory.videoTrack(with: source, trackId: UUID().uuidString)
    }

    func makeAudioSource(_ constraints: RTCMediaConstraints?) -> RTCAudioSource {
        factory.audioSource(with: constraints)
    }

    func makeAudioTrack(source: RTCAudioSource) -> RTCAudioTrack {
        factory.audioTrack(with: source, trackId: UUID().uuidString)
    }

    private func makePeerConnection(
        configuration: RTCConfiguration,
        constraints: RTCMediaConstraints,
        delegate: RTCPeerConnectionDelegate?
    ) throws -> RTCPeerConnection {
        guard let peerConnection = factory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: delegate
        ) else {
            throw ClientError.Unexpected()
        }
        
        return peerConnection
    }
}
