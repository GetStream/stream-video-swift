//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages local video media for a call session.
final class LocalVideoMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// The factory for creating WebRTC peer connection components.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The adapter for communicating with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    /// The video options for the call.
    private let videoOptions: VideoOptions

    /// The video configuration for the call.
    private let videoConfig: VideoConfig

    /// The factory for creating the capturer.
    private let capturerFactory: VideoCapturerProviding

    /// The stream identifiers for this video adapter.
    private let streamIds: [String]

    private let videoCaptureSessionProvider: VideoCaptureSessionProvider

    /// The local video track.
    private(set) var localTrack: RTCVideoTrack?

    /// The video capturer.
    private var capturer: CameraVideoCapturing?

    /// The RTP transceiver for sending video.
    private var sender: RTCRtpTransceiver?

    /// The mid (Media Stream Identification) of the sender.
    var mid: String? { sender?.mid }

    /// A publisher that emits track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Initializes a new instance of the local video media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The video options for the call.
    ///   - videoConfig: The video configuration for the call.
    ///   - subject: A publisher that emits track events.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>,
        capturerFactory: VideoCapturerProviding = StreamVideoCapturerFactory(),
        videoCaptureSessionProvider: VideoCaptureSessionProvider
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.videoOptions = videoOptions
        self.videoConfig = videoConfig
        self.subject = subject
        self.capturerFactory = capturerFactory
        self.videoCaptureSessionProvider = videoCaptureSessionProvider
        streamIds = ["\(sessionID):video"]
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        sender?.sender.track = nil
    }

    // MARK: - LocalMediaManaging

    /// Sets up the local video media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the video.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        let hasVideo = ownCapabilities.contains(.sendVideo)

        if hasVideo, localTrack == nil {
            try await makeVideoTrack(
                settings.cameraPosition == .front ? .front : .back
            )
            if sender == nil, settings.videoOn {
                sender = peerConnection.addTransceiver(
                    with: localTrack!,
                    init: RTCRtpTransceiverInit(
                        trackType: .video,
                        direction: .sendOnly,
                        streamIds: streamIds,
                        codecs: videoOptions.supportedCodecs
                    )
                )
            }
        } else if !hasVideo {
            Task { [weak self] in
                do {
                    try await self?.capturer?.stopCapture()
                } catch {
                    log.error(error)
                }
            }
        }

        localTrack?.isEnabled = settings.videoOn
    }

    /// Starts publishing the local video track.
    func publish() {
        Task { @MainActor [weak self] in
            guard
                let self,
                let localTrack,
                localTrack.isEnabled == false || sender == nil,
                let activeSession = videoCaptureSessionProvider.activeSession
            else {
                return
            }

            do {
                try await activeSession.capturer.startCapture(
                    device: activeSession.device
                )

                if sender == nil {
                    sender = peerConnection.addTransceiver(
                        with: localTrack,
                        init: RTCRtpTransceiverInit(
                            trackType: .video,
                            direction: .sendOnly,
                            streamIds: streamIds,
                            codecs: videoOptions.supportedCodecs
                        )
                    )
                } else {
                    sender?.sender.track = localTrack
                }
                localTrack.isEnabled = true
                log.debug("Local videoTrack trackId:\(localTrack.trackId) is now published.")
            } catch {
                log.error(error)
            }
        }
    }

    /// Stops publishing the local video track.
    func unpublish() {
        Task { @MainActor [weak self] in
            guard
                let self,
                let sender,
                let localTrack
            else { return }
            sender.sender.track = nil
            localTrack.isEnabled = false
            try? await capturer?.stopCapture()
            log.debug("Local videoTrack trackId:\(localTrack.trackId) is now unpublished.")
        }
    }

    /// Updates the local video media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        guard let localTrack else { return }
        let isMuted = !settings.videoOn
        let isLocalMuted = localTrack.isEnabled == false
        guard isMuted != isLocalMuted || sender == nil else {
            return
        }

        try await sfuAdapter.updateTrackMuteState(
            .video,
            isMuted: isMuted,
            for: sessionID
        )

        if isMuted, localTrack.isEnabled {
            unpublish()
        } else if !isMuted {
            publish()
        }
    }

    // MARK: - Camera Video

    /// Updates the camera position.
    ///
    /// - Parameter position: The new camera position.
    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await capturer?.setCameraPosition(position)
    }

    /// Sets a video filter.
    ///
    /// - Parameter videoFilter: The video filter to apply.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        capturer?.setVideoFilter(videoFilter)
    }

    /// Zooms the camera by a given factor.
    ///
    /// - Parameter factor: The zoom factor.
    func zoom(by factor: CGFloat) throws {
        try capturer?.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point to focus on.
    func focus(at point: CGPoint) throws {
        try capturer?.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try capturer?.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try capturer?.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try capturer?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try capturer?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Changes the publishing quality based on active encodings.
    ///
    /// - Parameter activeEncodings: The set of active encoding identifiers.
    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        Task { @MainActor [weak self] in
            guard
                let self,
                let sender,
                !activeEncodings.isEmpty
            else {
                return
            }

            var hasChanges = false
            let params = sender
                .sender
                .parameters
            var updatedEncodings = [RTCRtpEncodingParameters]()

            for encoding in params.encodings {
                guard let rid = encoding.rid else {
                    continue
                }
                let shouldEnable = activeEncodings.contains(rid)

                switch (shouldEnable, encoding.isActive) {
                case (true, true):
                    break
                case (false, false):
                    break
                default:
                    hasChanges = true
                    encoding.isActive = shouldEnable
                }
                updatedEncodings.append(encoding)
            }

            guard hasChanges else {
                return
            }
            params.encodings = updatedEncodings
            sender.sender.parameters = params

            let videoCodecs = VideoCodec
                .defaultCodecs
                .filter { activeEncodings.contains($0.quality) }

            if
                let activeSession = videoCaptureSessionProvider.activeSession,
                let device = activeSession.device {
                await activeSession.capturer.updateCaptureQuality(videoCodecs, on: device)
            }
        }
    }

    // MARK: - Private helpers

    /// Creates a new video track with the specified camera position.
    ///
    /// - Parameter position: The camera position to use.
    private func makeVideoTrack(
        _ position: AVCaptureDevice.Position
    ) async throws {
        if
            let activeSession = videoCaptureSessionProvider.activeSession,
            activeSession.position == position {
            capturer = activeSession.capturer
            localTrack = activeSession.localTrack
            localTrack?.isEnabled = false

            subject.send(
                .added(
                    id: sessionID,
                    trackType: .video,
                    track: activeSession.localTrack
                )
            )
        } else {
            let videoSource = peerConnectionFactory
                .makeVideoSource(forScreenShare: false)
            let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
            localTrack = videoTrack
            /// This is important to be false once we setUp as the activation will happen once
            /// publish is called (in order also to inform the SFU via the didUpdateCallSettings).
            videoTrack.isEnabled = false

            log.debug(
                """
                VideoTrack generated
                address:\(Unmanaged.passUnretained(videoTrack).toOpaque())
                trackId:\(videoTrack.trackId)
                mid: \(sender?.mid ?? "-")
                """
            )

            subject.send(
                .added(
                    id: sessionID,
                    trackType: .video,
                    track: videoTrack
                )
            )

            let cameraCapturer = capturerFactory.buildCameraCapturer(
                source: videoSource,
                options: videoOptions,
                filters: videoConfig.videoFilters
            )
            capturer = cameraCapturer

            let device = cameraCapturer.capturingDevice(for: position)
            try await cameraCapturer.startCapture(device: device)

            videoCaptureSessionProvider.activeSession = .init(
                position: position,
                device: device,
                localTrack: videoTrack,
                capturer: cameraCapturer
            )
        }
    }
}
