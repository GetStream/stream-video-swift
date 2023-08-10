//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

actor PeerConnectionFactory {
    
    static let supportedVideoCodecEncoding: [RTCVideoCodecInfo] = {
        RTCDefaultVideoEncoderFactory().supportedCodecs()
    }()
    
    static let supportedVideoCodecDecoding: [RTCVideoCodecInfo] = {
        RTCDefaultVideoDecoderFactory().supportedCodecs()
    }()
    
    private let factory: RTCPeerConnectionFactory
    private let videoConfig: VideoConfig
    
    init(videoConfig: VideoConfig) {
        self.videoConfig = videoConfig
        self.factory = Self.setupPeerConnectionFactory(videoConfig: videoConfig)
    }
    
    static func setupPeerConnectionFactory(videoConfig: VideoConfig) -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
        let defaultEncoderFactory = RTCDefaultVideoEncoderFactory()
//        let encoderFactory = RTCVideoEncoderFactorySimulcast(
//            primary: defaultEncoderFactory,
//            fallback: defaultEncoderFactory
//        )
        let encoderFactory = defaultEncoderFactory
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let factory: RTCPeerConnectionFactory
        if let audioDevice = videoConfig.audioDevice {
            factory = RTCPeerConnectionFactory(
                encoderFactory: encoderFactory,
                decoderFactory: decoderFactory,
                audioDevice: audioDevice
            )
        } else {
            factory = RTCPeerConnectionFactory(
                encoderFactory: encoderFactory,
                decoderFactory: decoderFactory
            )
        }
        
        return factory
    }
    
    func makePeerConnection(
        sessionId: String,
        callCid: String,
        configuration: RTCConfiguration,
        type: PeerConnectionType,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        constraints: RTCMediaConstraints = RTCMediaConstraints.defaultConstraints,
        videoOptions: VideoOptions,
        reportsStats: Bool = true
    ) throws -> PeerConnection {
        let pc = try makePeerConnection(
            configuration: configuration,
            constraints: constraints,
            delegate: nil
        )
        let peerConnection = PeerConnection(
            sessionId: sessionId,
            callCid: callCid,
            pc: pc,
            type: type,
            signalService: signalService,
            videoOptions: videoOptions,
            reportStats: reportsStats
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
