//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class PeerConnectionFactory: @unchecked Sendable {

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
    
    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource {
        factory.videoSource(forScreenCast: forScreenShare)
    }

    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
        factory.videoTrack(with: source, trackId: UUID().uuidString)
    }

    func makeAudioSource(_ constraints: RTCMediaConstraints?) -> RTCAudioSource {
        let result = factory.audioSource(with: constraints)
        log.debug(
            """
            AudioSource was created \(Unmanaged.passUnretained(result).toOpaque())
            """,
            subsystems: .webRTC
        )
        return result
    }

    func makeAudioTrack(source: RTCAudioSource) -> RTCAudioTrack {
        let result = factory.audioTrack(with: source, trackId: UUID().uuidString)
        log.debug(
            """
            AudioTrack was created \(Unmanaged.passUnretained(result).toOpaque())
            trackId: \(result.trackId)
            """,
            subsystems: .webRTC
        )
        return result
    }

    func makePeerConnection(
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
