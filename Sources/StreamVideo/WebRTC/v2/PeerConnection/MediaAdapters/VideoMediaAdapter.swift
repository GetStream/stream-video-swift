//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages video media for a call session.
final class VideoMediaAdapter: MediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// The factory for creating WebRTC peer connection components.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The manager for local video media.
    private let localMediaManager: LocalMediaAdapting

    /// A bag to store disposable resources.
    private let disposableBag = DisposableBag()

    /// A queue for synchronizing access to shared resources.
    private let queue = UnfairQueue()

    /// An array to store active media streams.
    private var streams: [RTCMediaStream] = []

    /// A subject for publishing track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// The local video track, if available.
    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalVideoMediaAdapter)?.localTrack
    }

    /// The mid (Media Stream Identification) of the local video track, if available.
    var mid: String? {
        (localMediaManager as? LocalVideoMediaAdapter)?.mid
    }

    /// Convenience initializer for creating a VideoMediaAdapter with a LocalVideoMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The video options for the call.
    ///   - videoConfig: The video configuration for the call.
    ///   - subject: A subject for publishing track events.
    convenience init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>,
        videoCaptureSessionProvider: VideoCaptureSessionProvider
    ) {
        self.init(
            sessionID: sessionID,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: LocalVideoMediaAdapter(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject,
                videoCaptureSessionProvider: videoCaptureSessionProvider
            ),
            subject: subject
        )
    }

    /// Initializes a new instance of the video media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - localMediaManager: The manager for local video media.
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
            .filter { $0.stream.trackType == .video }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .video }
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    // MARK: - MediaAdapting

    /// Sets up the video media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the video.
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

    /// Updates the video media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - Video

    /// Updates the camera position.
    ///
    /// - Parameter position: The new camera position.
    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await(localMediaManager as? LocalVideoMediaAdapter)?
            .didUpdateCameraPosition(position)
    }

    /// Sets a video filter.
    ///
    /// - Parameter videoFilter: The video filter to apply.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        (localMediaManager as? LocalVideoMediaAdapter)?
            .setVideoFilter(videoFilter)
    }

    /// Zooms the camera by a given factor.
    ///
    /// - Parameter factor: The zoom factor.
    func zoom(by factor: CGFloat) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point to focus on.
    func focus(at point: CGPoint) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try (localMediaManager as? LocalVideoMediaAdapter)?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Changes the publishing quality based on active encodings.
    ///
    /// - Parameter activeEncodings: The set of active encoding identifiers.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_VideoLayerSetting]
    ) {
        (localMediaManager as? LocalVideoMediaAdapter)?
            .changePublishQuality(with: layerSettings)
    }

    // MARK: - Observers

    /// Adds a new video stream and notifies observers.
    ///
    /// - Parameter stream: The video stream to add.
    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .video,
                    track: videoTrack
                )
            )
        }
    }

    /// Removes a video stream and notifies observers.
    ///
    /// - Parameter stream: The video stream to remove.
    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
        }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .removed(
                    id: stream.streamId,
                    trackType: .video,
                    track: videoTrack
                )
            )
        }
    }
}
