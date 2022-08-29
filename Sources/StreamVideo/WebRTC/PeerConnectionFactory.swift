//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

actor PeerConnectionFactory {
    
    private let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let defaultEncoderFactory = RTCDefaultVideoEncoderFactory()
        let encoderFactory = RTCVideoEncoderFactorySimulcast(
            primary: defaultEncoderFactory,
            fallback: defaultEncoderFactory
        )
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let factory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
        return factory
    }()
    
    func makePeerConnection(
        sessionId: String,
        configuration: RTCConfiguration,
        type: PeerConnectionType,
        signalService: Stream_Video_Sfu_SignalServer,
        constraints: RTCMediaConstraints = RTCMediaConstraints.defaultConstraints
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
            signalService: signalService
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
