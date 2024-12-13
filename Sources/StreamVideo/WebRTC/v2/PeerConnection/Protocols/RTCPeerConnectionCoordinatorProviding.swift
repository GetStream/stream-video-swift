//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// A protocol that defines a factory method for creating RTCPeerConnectionCoordinator instances.
///
/// The `RTCPeerConnectionCoordinatorProviding` protocol is designed to abstract the creation of
/// `RTCPeerConnectionCoordinator` objects. This allows for flexibility in how these coordinators
/// are instantiated and configured, which can be particularly useful for dependency injection and testing.
protocol RTCPeerConnectionCoordinatorProviding {

    /// Builds and returns an RTCPeerConnectionCoordinator with the specified parameters.
    /// - Parameters:
    ///   - sessionId: A unique identifier for the peer connection session.
    ///   - peerType: The type of peer connection (e.g., publisher, subscriber).
    ///   - peerConnection: The StreamRTCPeerConnectionProtocol instance to be managed.
    ///   - peerConnectionFactory: The factory used to create WebRTC-related objects.
    ///   - videoOptions: Options for configuring video behavior.
    ///   - videoConfig: Configuration settings for video.
    ///   - callSettings: Settings related to the overall call.
    ///   - audioSettings: Settings for audio configuration.
    ///   - publishOptions: The publishOptions to use to create the initial tracks.
    ///   - sfuAdapter: The adapter for interacting with the Selective Forwarding Unit.
    ///   - videoCaptureSessionProvider: Provider for video capturing functionality.
    ///   - screenShareSessionProvider: Provider for screen sharing functionality.
    /// - Returns: An initialized `RTCPeerConnectionCoordinator` instance.
    func buildCoordinator(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        publishOptions: PublishOptions,
        sfuAdapter: SFUAdapter,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) -> RTCPeerConnectionCoordinator
}

/// A concrete implementation of the RTCPeerConnectionCoordinatorProviding protocol.
///
/// The `StreamRTCPeerConnectionCoordinatorFactory` class provides a specific implementation for creating
/// `RTCPeerConnectionCoordinator` instances. It adheres to the `RTCPeerConnectionCoordinatorProviding`
/// protocol and offers a straightforward way to instantiate coordinators with the given parameters.
final class StreamRTCPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding {
    /// Creates and returns an RTCPeerConnectionCoordinator with the specified parameters.
    /// - Parameters:
    ///   - sessionId: A unique identifier for the peer connection session.
    ///   - peerType: The type of peer connection (e.g., publisher, subscriber).
    ///   - peerConnection: The StreamRTCPeerConnectionProtocol instance to be managed.
    ///   - peerConnectionFactory: The factory used to create WebRTC-related objects.
    ///   - videoOptions: Options for configuring video behavior.
    ///   - videoConfig: Configuration settings for video.
    ///   - callSettings: Settings related to the overall call.
    ///   - audioSettings: Settings for audio configuration.
    ///   - publishOptions: TODO
    ///   - sfuAdapter: The adapter for interacting with the Selective Forwarding Unit.
    ///   - videoCaptureSessionProvider: Provider for video capturing functionality.
    ///   - screenShareSessionProvider: Provider for screen sharing functionality.
    /// - Returns: A newly created `RTCPeerConnectionCoordinator` instance.
    func buildCoordinator(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        publishOptions: PublishOptions,
        sfuAdapter: SFUAdapter,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) -> RTCPeerConnectionCoordinator {
        RTCPeerConnectionCoordinator(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            videoCaptureSessionProvider: videoCaptureSessionProvider,
            screenShareSessionProvider: screenShareSessionProvider
        )
    }
}
