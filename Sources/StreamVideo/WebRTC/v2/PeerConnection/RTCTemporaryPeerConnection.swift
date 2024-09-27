//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A temporary peer connection used for creating offers with specific tracks.
final class RTCTemporaryPeerConnection {

    private let peerConnection: StreamRTCPeerConnectionProtocol
    private let localAudioTrack: RTCAudioTrack?
    private let localVideoTrack: RTCVideoTrack?
    private let videoOptions: VideoOptions

    /// Initializes a new RTCTemporaryPeerConnection.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the session.
    ///   - peerConnectionFactory: The factory for creating WebRTC objects.
    ///   - configuration: The configuration for the peer connection.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The options for video configuration.
    ///   - localAudioTrack: The local audio track to add to the connection, if any.
    ///   - localVideoTrack: The local video track to add to the connection, if any.
    ///
    /// - Throws: An error if the peer connection creation fails.
    init(
        sessionID: String,
        peerConnectionFactory: PeerConnectionFactory,
        configuration: RTCConfiguration,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        localAudioTrack: RTCAudioTrack?,
        localVideoTrack: RTCVideoTrack?
    ) throws {
        peerConnection = try StreamRTCPeerConnection(
            peerConnectionFactory,
            configuration: configuration
        )
        self.localAudioTrack = localAudioTrack
        self.localVideoTrack = localVideoTrack
        self.videoOptions = videoOptions
    }

    /// Cleans up resources when the instance is being deallocated.
    deinit {
        peerConnection.transceivers.forEach { $0.stopInternal() }
        peerConnection.close()
    }

    /// Creates an offer for the temporary peer connection.
    ///
    /// This method adds the local audio and video tracks (if available) to the peer connection
    /// as receive-only transceivers before creating the offer.
    ///
    /// - Returns: An `RTCSessionDescription` representing the created offer.
    /// - Throws: An error if the offer creation fails.
    func createOffer() async throws -> RTCSessionDescription {
        if let localAudioTrack {
            _ = peerConnection.addTransceiver(
                with: localAudioTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .audio,
                    direction: .recvOnly,
                    streamIds: ["temp-audio"]
                )
            )
        }

        if let localVideoTrack {
            _ = peerConnection.addTransceiver(
                with: localVideoTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .video,
                    direction: .recvOnly,
                    streamIds: ["temp-video"],
                    codecs: videoOptions.supportedCodecs
                )
            )
        }
        return try await peerConnection.offer(for: .defaultConstraints)
    }
}
