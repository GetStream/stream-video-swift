//
//  RTCTemporaryPeerConnection.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 6/8/24.
//

import Foundation
import StreamWebRTC

final class RTCTemporaryPeerConnection {

    private let peerConnection: PeerConnection
    private let localAudioTrack: RTCAudioTrack?
    private let localVideoTrack: RTCVideoTrack?

    init(
        sessionID: String,
        peerConnectionFactory: PeerConnectionFactory,
        configuration: RTCConfiguration,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        localAudioTrack: RTCAudioTrack?,
        localVideoTrack: RTCVideoTrack?
    ) throws {
        self.peerConnection = try peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: configuration,
            type: .subscriber,
            sfuAdapter: sfuAdapter,
            videoOptions: videoOptions
        )
        self.localAudioTrack = localAudioTrack
        self.localVideoTrack = localVideoTrack
    }

    deinit {
        peerConnection.transceiver?.stopInternal()
        peerConnection.close()
    }

    func createOffer() async throws -> RTCSessionDescription {
        if let localAudioTrack {
            peerConnection.addTrack(
                localAudioTrack,
                streamIds: ["temp-audio"],
                trackType: .audio
            )
        }

        if let localVideoTrack {
            peerConnection.addTransceiver(
                localVideoTrack,
                streamIds: ["temp-video"],
                direction: .recvOnly,
                trackType: .video
            )
        }
        return try await peerConnection.createOffer()
    }
}
