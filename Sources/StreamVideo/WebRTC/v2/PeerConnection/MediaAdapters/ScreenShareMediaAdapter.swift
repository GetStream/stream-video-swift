//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages screen sharing media for a call session.
final class ScreenShareMediaAdapter: MediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// The factory for creating WebRTC peer connection components.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The manager for local screen sharing media.
    private let localMediaManager: LocalMediaAdapting

    /// A bag to store disposable resources.
    private let disposableBag = DisposableBag()

    /// A queue for synchronizing access to shared resources.
    private let queue = UnfairQueue()

    /// An array to store active media streams.
    private var streams: [RTCMediaStream] = []

    /// A subject for publishing track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// The local screen share track, if available.
    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalScreenShareMediaAdapter)?.localTrack
    }

    /// The mid (Media Stream Identification) of the local screen share track, if available.
    var mid: String? {
        (localMediaManager as? LocalScreenShareMediaAdapter)?.mid
    }

    /// Convenience initializer for creating a ScreenShareMediaAdapter with a LocalScreenShareMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The video options for the call.
    ///   - videoConfig: The video configuration for the call.
    ///   - subject: A subject for publishing track events.
    ///   - screenShareSessionProvider: Provides access to the active screen sharing session.
    convenience init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.init(
            sessionID: sessionID,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: LocalScreenShareMediaAdapter(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject,
                screenShareSessionProvider: screenShareSessionProvider
            ),
            subject: subject
        )
    }

    /// Initializes a new instance of the screen share media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - localMediaManager: The manager for local screen sharing media.
    ///   - subject: A subject for publishing track events.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        localMediaManager: LocalMediaAdapting,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.localMediaManager = localMediaManager
        self.subject = subject

        // Set up observers for added and removed streams
        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.AddedStreamEvent.self)
            .filter { $0.stream.trackType == .screenshare }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .screenshare }
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    // MARK: - MediaAdapting

    /// Sets up the screen share media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the screen share.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await localMediaManager.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    /// Updates the screen share media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - ScreenSharing

    /// Begins screen sharing of the specified type.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to begin.
    ///   - ownCapabilities: The capabilities of the local participant.
    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        guard
            let localScreenShareMediaManager = localMediaManager as? LocalScreenShareMediaAdapter
        else {
            return
        }

        try await localScreenShareMediaManager.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
    }

    /// Stops the current screen sharing session.
    func stopScreenSharing() async throws {
        guard
            let localScreenShareMediaManager = localMediaManager as? LocalScreenShareMediaAdapter
        else {
            return
        }

        try await localScreenShareMediaManager.stopScreenSharing()
    }

    // MARK: - Observers

    /// Adds a new screen share stream and notifies observers.
    ///
    /// - Parameter stream: The screen share stream to add.
    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .screenshare,
                    track: videoTrack
                )
            )
        }
    }

    /// Removes a screen share stream and notifies observers.
    ///
    /// - Parameter stream: The screen share stream to remove.
    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
        }
        if let videoTrack = stream.audioTracks.first {
            subject.send(
                .removed(
                    id: stream.streamId,
                    trackType: .screenshare,
                    track: videoTrack
                )
            )
        }
    }
}
