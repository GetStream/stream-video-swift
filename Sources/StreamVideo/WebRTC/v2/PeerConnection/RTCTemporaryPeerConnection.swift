//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A temporary peer connection used for creating offers with specific tracks.
final class RTCTemporaryPeerConnection {

    private let peerConnection: StreamRTCPeerConnectionProtocol
    private let direction: RTCRtpTransceiverDirection
    private let localAudioTrack: RTCAudioTrack
    private let localVideoTrack: RTCVideoTrack
    private let videoOptions: VideoOptions

    convenience init(
        peerConnectionType: PeerConnectionType,
        coordinator: WebRTCCoordinator,
        sfuAdapter: SFUAdapter
    ) async throws {
        let peerConnectionFactory = coordinator.stateAdapter.peerConnectionFactory
        let audioSource = peerConnectionFactory.makeAudioSource(.defaultConstraints)
        let audioTrack = peerConnectionFactory.makeAudioTrack(source: audioSource)

        let videoSource = peerConnectionFactory.makeVideoSource(forScreenShare: false)
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)

        try await self.init(
            direction: peerConnectionType == .subscriber ? .recvOnly : .sendOnly,
            sessionID: coordinator.stateAdapter.sessionID,
            peerConnectionFactory: coordinator.stateAdapter.peerConnectionFactory,
            configuration: coordinator.stateAdapter.connectOptions.rtcConfiguration,
            sfuAdapter: sfuAdapter,
            videoOptions: coordinator.stateAdapter.videoOptions,
            localAudioTrack: audioTrack,
            localVideoTrack: videoTrack
        )
    }

    /// Initializes a new RTCTemporaryPeerConnection.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the session.
    ///   - peerConnectionFactory: The factory for creating WebRTC objects.
    ///   - configuration: The configuration for the peer connection.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The options for video configuration.
    ///   - localAudioTrack: The local audio track to add to the connection.
    ///   - localVideoTrack: The local video track to add to the connection.
    ///
    /// - Throws: An error if the peer connection creation fails.
    private init(
        direction: RTCRtpTransceiverDirection,
        sessionID: String,
        peerConnectionFactory: PeerConnectionFactory,
        configuration: RTCConfiguration,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        localAudioTrack: RTCAudioTrack,
        localVideoTrack: RTCVideoTrack
    ) throws {
        peerConnection = try StreamRTCPeerConnection(
            peerConnectionFactory,
            configuration: configuration
        )
        self.direction = direction
        self.localAudioTrack = localAudioTrack
        self.localVideoTrack = localVideoTrack
        self.videoOptions = videoOptions
    }

    /// Cleans up resources when the instance is being deallocated.
    deinit {
        peerConnection.transceivers.forEach { $0.stopInternal() }
        // swiftlint:disable discourage_task_init
        Task { [peerConnection] in await peerConnection.close() }
        // swiftlint:enable discourage_task_init
    }

    /// Creates an offer for the temporary peer connection.
    ///
    /// This method adds the local audio and video tracks (if available) to the peer connection
    /// as receive-only transceivers before creating the offer.
    ///
    /// - Returns: An `RTCSessionDescription` representing the created offer.
    /// - Throws: An error if the offer creation fails.
    func createOffer() async throws -> RTCSessionDescription {
        _ = peerConnection.addTransceiver(
            trackType: .audio,
            with: localAudioTrack,
            init: .temporary(trackType: .audio)
        )

        _ = peerConnection.addTransceiver(
            trackType: .video,
            with: localVideoTrack,
            init: .temporary(trackType: .video)
        )
        
        return try await peerConnection.offer(for: .defaultConstraints)
    }
}
