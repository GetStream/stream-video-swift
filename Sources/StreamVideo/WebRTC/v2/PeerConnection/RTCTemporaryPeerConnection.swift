//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Creates an offer without retaining a peer connection for the call.
///
/// `createOffer()` disables its tracks and awaits native closure on both
/// success and error. Deinitialization also requests closure as a fallback,
/// but cannot wait for it.
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

        let peerConnection = try StreamRTCPeerConnection(
            peerConnectionFactory,
            configuration: await coordinator.stateAdapter.connectOptions.rtcConfiguration
        )

        self.init(
            peerConnection: peerConnection,
            direction: peerConnectionType == .subscriber ? .recvOnly : .sendOnly,
            videoOptions: await coordinator.stateAdapter.videoOptions,
            localAudioTrack: audioTrack,
            localVideoTrack: videoTrack
        )
    }

    /// Uses an existing connection and tracks for a single offer.
    /// `createOffer()` disables both tracks and awaits connection closure.
    init(
        peerConnection: StreamRTCPeerConnectionProtocol,
        direction: RTCRtpTransceiverDirection,
        videoOptions: VideoOptions,
        localAudioTrack: RTCAudioTrack,
        localVideoTrack: RTCVideoTrack
    ) {
        self.peerConnection = peerConnection
        self.direction = direction
        self.localAudioTrack = localAudioTrack
        self.localVideoTrack = localVideoTrack
        self.videoOptions = videoOptions
    }

    /// Cleans up resources when the instance is being deallocated.
    deinit {
        // `createOffer` closes the connection on both success and error.
        // Cancellation can still skip that path, so keep a close as a
        // safety net. Do not inspect transceivers here; a closed PC can
        // block the deinit thread.
        let peerConnection = peerConnection
        // swiftlint:disable discourage_task_init
        Task { await peerConnection.close() }
        // swiftlint:enable discourage_task_init
    }

    /// Creates an offer for the temporary peer connection.
    ///
    /// Adds temporary send-only audio and video transceivers, then creates
    /// the offer. Both tracks are disabled and the connection is closed
    /// before this method returns or throws.
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

        do {
            let offer = try await peerConnection.offer(
                for: .defaultConstraints
            )
            await tearDownMedia()
            return offer
        } catch {
            await tearDownMedia()
            throw error
        }
    }

    /// Disables both tracks and waits for native closure before returning.
    ///
    /// Leaving the audio track enabled after the offer can keep AURemoteIO
    /// delivering into a VoiceEngine while its factory is being released.
    private func tearDownMedia() async {
        localAudioTrack.isEnabled = false
        localVideoTrack.isEnabled = false
        await peerConnection.close()
    }
}
