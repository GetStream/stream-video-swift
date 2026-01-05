//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    ///   - publishOptions: The publishOptions to use for creating the initial tracks
    ///   - audioSession: The audio session manager.
    ///   - videoCaptureSessionProvider: Provides access to the active video capturing session.
    ///   - screenShareSessionProvider: Provides access to the active screen
    ///     sharing session.
    ///   - audioDeviceModule: The audio device module shared with capturers.
    convenience init(
        sessionID: String,
        peerConnectionType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        publishOptions: PublishOptions,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider,
        audioDeviceModule: AudioDeviceModule
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
                    publishOptions: publishOptions.audio,
                    subject: subject
                ),
                videoMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    sfuAdapter: sfuAdapter,
                    videoOptions: videoOptions,
                    videoConfig: videoConfig,
                    publishOptions: publishOptions.video,
                    subject: subject,
                    videoCaptureSessionProvider: videoCaptureSessionProvider,
                    audioDeviceModule: audioDeviceModule
                ),
                screenShareMediaAdapter: .init(
                    sessionID: sessionID,
                    peerConnection: peerConnection,
                    peerConnectionFactory: peerConnectionFactory,
                    sfuAdapter: sfuAdapter,
                    publishOptions: publishOptions.screenShare,
                    subject: subject,
                    screenShareSessionProvider: screenShareSessionProvider,
                    audioDeviceModule: audioDeviceModule
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
    
    /// Retrieves track information for a specified track type and collection type.
    ///
    /// - Parameters:
    ///   - type: The type of track (audio, video, screenshare).
    ///   - collectionType: The collection type for the track info.
    /// - Returns: An array of track information models.
    func trackInfo(
        for type: TrackType,
        collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        switch type {
        case .audio:
            return audioMediaAdapter.trackInfo(for: collectionType)
        case .video:
            return videoMediaAdapter.trackInfo(for: collectionType)
        case .screenshare:
            return screenShareMediaAdapter.trackInfo(for: collectionType)
        default:
            return []
        }
    }
    
    /// Updates the media adapters based on new publish options.
    ///
    /// - Parameter publishOptions: The updated publish options.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) {
            [audioMediaAdapter, videoMediaAdapter, screenShareMediaAdapter] group in
            group.addTask {
                try await audioMediaAdapter.didUpdatePublishOptions(publishOptions)
            }
            
            group.addTask {
                try await videoMediaAdapter.didUpdatePublishOptions(publishOptions)
            }
            
            group.addTask {
                try await screenShareMediaAdapter.didUpdatePublishOptions(publishOptions)
            }
            
            while try await group.next() != nil {}
        }
    }
    
    /// Changes the publishing quality based on active encodings.
    ///
    /// - Parameter activeEncodings: The set of active encoding identifiers.
    func changePublishQuality(
        with event: Stream_Video_Sfu_Event_ChangePublishQuality
    ) async {
        await withTaskGroup(of: Void.self) { [audioMediaAdapter, videoMediaAdapter, screenShareMediaAdapter] group in
            group.addTask {
                audioMediaAdapter.changePublishQuality(
                    with: event.audioSenders.filter { $0.trackType == .audio }
                )
            }
            
            group.addTask {
                videoMediaAdapter.changePublishQuality(
                    with: event.videoSenders.filter { $0.trackType == .video }
                )
            }
            
            group.addTask {
                screenShareMediaAdapter.changePublishQuality(
                    with: event.videoSenders.filter { $0.trackType == .screenShare }
                )
            }
            
            while await group.next() != nil {}
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
    func zoom(by factor: CGFloat) async throws {
        try await videoMediaAdapter.zoom(by: factor)
    }
    
    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point to focus on.
    func focus(at point: CGPoint) async throws {
        try await videoMediaAdapter.focus(at: point)
    }
    
    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await videoMediaAdapter.addVideoOutput(videoOutput)
    }
    
    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await videoMediaAdapter.removeVideoOutput(videoOutput)
    }
    
    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await videoMediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }
    
    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await videoMediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }
    
    // MARK: - ScreenSharing
    
    /// Begins screen sharing of the specified type.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to begin.
    ///   - ownCapabilities: The capabilities of the local participant.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability],
        includeAudio: Bool
    ) async throws {
        try await screenShareMediaAdapter.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities,
            includeAudio: includeAudio
        )
    }
    
    /// Stops the current screen sharing session.
    func stopScreenSharing() async throws {
        try await screenShareMediaAdapter.stopScreenSharing()
    }
}
