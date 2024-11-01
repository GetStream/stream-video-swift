//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages audio, video, and screen sharing media for a call session.
final class MediaAdapter {

    /// The adapter for managing audio media.
    private let audioMediaAdapter: AudioMediaAdapter

    /// The adapter for managing video media.
    private let videoMediaAdapter: VideoMediaAdapter

    /// The adapter for managing screen share media.
    private let screenShareMediaAdapter: ScreenShareMediaAdapter

    /// A subject for publishing track events.
    private let subject: PassthroughSubject<TrackEvent, Never>

    /// A publisher for track events.
    /// - Note: We streamline track updates to a userInteractive queue to ensure, no events loss.
    var trackPublisher: AnyPublisher<TrackEvent, Never> {
        subject
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .eraseToAnyPublisher()
    }

    /// Initializes a new instance of the media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnectionType: The type of peer connection (publisher or subscriber).
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The video options for the call.
    ///   - videoConfig: The video configuration for the call.
    ///   - audioSession: The audio session manager.
    ///   - videoCaptureSessionProvider: Provides access to the active video capturing session.
    ///   - screenShareSessionProvider: Provides access to the active screen sharing session.
    convenience init(
        sessionID: String,
        peerConnectionType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        let subject = PassthroughSubject<TrackEvent, Never>()

        switch peerConnectionType {
        case .subscriber:
            self.init(
                subject: subject,
                audioMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                    subject: subject
                ),
                videoMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                    subject: subject
                ),
                screenShareMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                    subject: subject
                )
            )

        case .publisher:
            self.init(
                subject: subject,
                audioMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    sfuAdapter: sfuAdapter,
                    subject: subject
                ),
                videoMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    sfuAdapter: sfuAdapter,
                    videoOptions: videoOptions,
                    videoConfig: videoConfig,
                    subject: subject,
                    videoCaptureSessionProvider: videoCaptureSessionProvider
                ),
                screenShareMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    sfuAdapter: sfuAdapter,
                    videoOptions: videoOptions,
                    videoConfig: videoConfig,
                    subject: subject,
                    screenShareSessionProvider: screenShareSessionProvider
                )
            )
        }
    }

    init(
        subject: PassthroughSubject<TrackEvent, Never>,
        audioMediaAdapter: AudioMediaAdapter,
        videoMediaAdapter: VideoMediaAdapter,
        screenShareMediaAdapter: ScreenShareMediaAdapter
    ) {
        self.subject = subject
        self.audioMediaAdapter = audioMediaAdapter
        self.videoMediaAdapter = videoMediaAdapter
        self.screenShareMediaAdapter = screenShareMediaAdapter
    }

    /// Sets up the media adapters with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the media.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [audioMediaAdapter, videoMediaAdapter, screenShareMediaAdapter] group in
            group.addTask {
                try await audioMediaAdapter.setUp(
                    with: settings,
                    ownCapabilities: ownCapabilities
                )
            }

            group.addTask {
                try await videoMediaAdapter.setUp(
                    with: settings,
                    ownCapabilities: ownCapabilities
                )
            }

            group.addTask {
                try await screenShareMediaAdapter.setUp(
                    with: settings,
                    ownCapabilities: ownCapabilities
                )
            }

            while try await group.next() != nil {}
        }
    }

    /// Updates the media adapters based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [audioMediaAdapter, videoMediaAdapter, screenShareMediaAdapter] group in
            group.addTask {
                try await audioMediaAdapter.didUpdateCallSettings(settings)
            }

            group.addTask {
                try await videoMediaAdapter.didUpdateCallSettings(settings)
            }

            group.addTask {
                try await screenShareMediaAdapter.didUpdateCallSettings(settings)
            }

            while try await group.next() != nil {}
        }
    }

    /// Returns the local track for the specified track type.
    ///
    /// - Parameter type: The type of track to retrieve.
    /// - Returns: The local media track, if available.
    func localTrack(of type: TrackType) -> RTCMediaStreamTrack? {
        switch type {
        case .audio:
            return audioMediaAdapter.localTrack
        case .video:
            return videoMediaAdapter.localTrack
        case .screenshare:
            return screenShareMediaAdapter.localTrack
        default:
            return nil
        }
    }

    /// Returns the mid (Media Stream Identification) for the specified track type.
    ///
    /// - Parameter type: The type of track to retrieve the mid for.
    /// - Returns: The mid of the track, if available.
    func mid(for type: TrackType) -> String? {
        switch type {
        case .audio:
            return audioMediaAdapter.mid
        case .video:
            return videoMediaAdapter.mid
        case .screenshare:
            return screenShareMediaAdapter.mid
        default:
            return nil
        }
    }

    // MARK: - Video

    /// Updates the camera position.
    ///
    /// - Parameter position: The new camera position.
    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await videoMediaAdapter.didUpdateCameraPosition(position)
    }

    /// Sets a video filter.
    ///
    /// - Parameter videoFilter: The video filter to apply.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoMediaAdapter.setVideoFilter(videoFilter)
    }

    /// Zooms the camera by a given factor.
    ///
    /// - Parameter factor: The zoom factor.
    func zoom(by factor: CGFloat) throws {
        try videoMediaAdapter.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point to focus on.
    func focus(at point: CGPoint) throws {
        try videoMediaAdapter.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try videoMediaAdapter.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try videoMediaAdapter.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try videoMediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try videoMediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Changes the publishing quality based on active encodings.
    ///
    /// - Parameter activeEncodings: The set of active encoding identifiers.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_VideoLayerSetting]
    ) {
        videoMediaAdapter.changePublishQuality(with: layerSettings)
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
        try await screenShareMediaAdapter.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
    }

    /// Stops the current screen sharing session.
    func stopScreenSharing() async throws {
        try await screenShareMediaAdapter.stopScreenSharing()
    }
}
