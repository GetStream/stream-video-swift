//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class RTCTemporaryPeerConnection {

    private let peerConnection: StreamRTCPeerConnection
    private let localAudioTrack: RTCAudioTrack?
    private let localVideoTrack: RTCVideoTrack?
    private let videoOptions: VideoOptions

    init(
        sessionID: String,
        peerConnectionFactory: PeerConnectionFactory,
        configuration: RTCConfiguration,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        localAudioTrack: RTCAudioTrack?,
        localVideoTrack: RTCVideoTrack?
    ) throws {
        peerConnection = try peerConnectionFactory.makePeerConnection(
            configuration: configuration,
            constraints: .defaultConstraints,
            delegate: nil
        )
        self.localAudioTrack = localAudioTrack
        self.localVideoTrack = localVideoTrack
        self.videoOptions = videoOptions
    }

    deinit {
        peerConnection.transceivers.forEach { $0.stopInternal() }
        peerConnection.close()
    }

    func createOffer() async throws -> RTCSessionDescription {
        if let localAudioTrack {
            peerConnection.addTransceiver(
                with: localAudioTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .audio,
                    direction: .recvOnly,
                    streamIds: ["temp-audio"]
                )
            )
        }

        if let localVideoTrack {
            peerConnection.addTransceiver(
                with: localVideoTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .video,
                    direction: .recvOnly,
                    streamIds: ["temp-video"],
                    codecs: videoOptions.supportedCodecs
                )
            )
        }
        return try await peerConnection.createOffer()
    }
}
