//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@preconcurrency import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// A class that manages local video media for a call session.
///
/// `LocalVideoMediaAdapter` handles the configuration, lifecycle, and
/// publication of local video tracks in a WebRTC session. It supports dynamic
/// video settings such as camera switching, zoom, and focus, and integrates
/// seamlessly with the WebRTC framework.
final class LocalVideoMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    @Injected(\.videoCapturePolicy) private var videoCapturePolicy
    @Injected(\.captureDeviceProvider) private var captureDeviceProvider

    /// A unique identifier representing the current call session.
    private let sessionID: String

    /// The WebRTC peer connection used for handling media streams.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// A factory for creating WebRTC components such as video sources and tracks.
    private let peerConnectionFactory: PeerConnectionFactory

    /// An adapter for communicating with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    /// Options that define the video settings for the current call.
    private let videoOptions: VideoOptions

    /// Configuration details for video, such as resolution and frame rate.
    private let videoConfig: VideoConfig

    /// The current publish options for the video track, defining encodings and layers.
    private var publishOptions: [PublishOptions.VideoPublishOptions]

    /// A factory for creating video capturers based on the current settings.
    private let capturerFactory: VideoCapturerProviding

    /// Stream identifiers associated with this adapter, used for tracking.
    private let streamIds: [String]

    /// A storage container for managing video transceivers.
    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.VideoPublishOptions>(for: .video)

    /// The primary video track used in the current session.
    private let primaryTrack: RTCVideoTrack

    /// A provider for managing the video capture session.
    private let videoCaptureSessionProvider: VideoCaptureSessionProvider

    /// The capturer responsible for capturing video frames.
    private var capturer: StreamVideoCapturer?

    /// A publisher that emits events related to video track changes.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// A container for managing cancellable tasks to ensure proper cleanup.
    private let disposableBag = DisposableBag()

    private let publishUnpublishProcessingQueue = SerialActorQueue()

    /// Initializes a new instance of the `LocalVideoMediaAdapter`.
    ///
    /// - Parameters:
    ///   - sessionID: A unique identifier for the call session.
    ///   - peerConnection: The WebRTC peer connection for handling media.
    ///   - peerConnectionFactory: A factory for creating WebRTC components.
    ///   - sfuAdapter: An adapter for communicating with the SFU.
    ///   - videoOptions: The video settings for the call.
    ///   - videoConfig: Configuration for video, such as resolution and frame rate.
    ///   - publishOptions: Initial publish options for the video track.
    ///   - subject: A publisher for track-related events.
    ///   - capturerFactory: A factory for creating video capturers. Defaults to `StreamVideoCapturerFactory`.
    ///   - videoCaptureSessionProvider: A provider for managing video capture sessions.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        publishOptions: [PublishOptions.VideoPublishOptions],
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
        self.publishOptions = publishOptions
        self.subject = subject
        self.capturerFactory = capturerFactory
        self.videoCaptureSessionProvider = videoCaptureSessionProvider

        // Initialize the primary video track, either from the active session or a new source.
        primaryTrack = {
            let source = videoCaptureSessionProvider
                .activeSession?
                .localTrack
                .source ?? peerConnectionFactory.makeVideoSource(forScreenShare: false)
            return peerConnectionFactory.makeVideoTrack(source: source)
        }()
        primaryTrack.isEnabled = false
        videoCaptureSessionProvider.activeSession?.localTrack = primaryTrack
        streamIds = ["\(sessionID):video"]
    }

    /// Cleans up resources when the instance is deallocated.
    ///
    /// Removes all transceivers from storage and logs details about the
    /// deallocation process.
    deinit {
        Task { @MainActor [transceiverStorage] in
            transceiverStorage.removeAll()
        }

        log.debug(
            """
            Local video tracks will be deallocated:
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )
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
        subject.send(
            .added(
                id: sessionID,
                trackType: .video,
                track: primaryTrack
            )
        )

        guard ownCapabilities.contains(.sendVideo) else {
            try await videoCaptureSessionProvider.activeSession?.capturer.stopCapture()
            videoCaptureSessionProvider.activeSession = nil
            log.debug("Active video capture session stopped because user has no capabilities for video.")
            return
        }

        try await configureActiveVideoCaptureSession(
            position: settings.cameraPosition == .back ? .back : .front,
            track: primaryTrack
        )
    }

    /// Starts publishing the local video track.
    func publish() {
        publishUnpublishProcessingQueue.async { @MainActor [weak self] in
            guard
                let self,
                !primaryTrack.isEnabled
            else {
                return
            }
            primaryTrack.isEnabled = true

            do {
                try await startVideoCapturingSession()
            } catch {
                log.error(error)
            }

            publishOptions
                .forEach {
                    self.addOrUpdateTransceiver(
                        for: $0,
                        with: self
                            .primaryTrack
                            .clone(from: self.peerConnectionFactory)
                    )
                }

            log.debug(
                """
                Local videoTracks are now published
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Stops publishing the local video track.
    func unpublish() {
        publishUnpublishProcessingQueue.async { [weak self] in
            guard
                let self,
                primaryTrack.isEnabled
            else {
                return
            }

            primaryTrack.isEnabled = false

            transceiverStorage
                .forEach { $0.value.sender.track?.isEnabled = false }

            Task { @MainActor [weak self] in
                do {
                    try await self?.stopVideoCapturingSession()
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }

            log.debug(
                """
                Local videoTracks are now unpublished:
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Updates the local video media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        let isMuted = !settings.videoOn
        let isLocalMuted = primaryTrack.isEnabled == false

        if isMuted != isLocalMuted {
            try await sfuAdapter.updateTrackMuteState(
                .video,
                isMuted: isMuted,
                for: sessionID
            )
        }

        if isMuted, primaryTrack.isEnabled {
            unpublish()
        } else if !isMuted {
            publish()
        }
    }

    /// Updates the publish options for the video track.
    ///
    /// - Parameter publishOptions: The updated publish options.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        guard primaryTrack.isEnabled else { return }

        self.publishOptions = publishOptions.video

        for publishOption in self.publishOptions {
            addOrUpdateTransceiver(
                for: publishOption,
                with: primaryTrack.clone(from: peerConnectionFactory)
            )
        }

        let activePublishOptions = Set(self.publishOptions)

        transceiverStorage
            .filter { !activePublishOptions.contains($0.key) }
            .forEach { $0.value.sender.track = nil }

        log.debug(
            """
            Local videoTracks updated with:
                PublishOptions:
                    \(self.publishOptions.map { "\($0)" }.joined(separator: "\n"))
                
                TransceiverStorage:
                    \(transceiverStorage)
            """,
            subsystems: .webRTC
        )
    }

    /// Retrieves track information for the local video tracks.
    ///
    /// - Returns: An array of track information, including ID and layers.
    func trackInfo() -> [Stream_Video_Sfu_Models_TrackInfo] {
        transceiverStorage
            .filter { $0.value.sender.track != nil }
            .compactMap { publishOptions, transceiver in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .video
                trackInfo.trackID = transceiver.sender.track?.trackId ?? ""
                trackInfo.layers = publishOptions.buildLayers(for: .video)
                trackInfo.mid = transceiver.mid
                trackInfo.muted = transceiver.sender.track?.isEnabled ?? true
                return trackInfo
            }
    }

    /// Changes the publishing quality based on active encodings.
    ///
    /// - Parameter activeEncodings: The set of active encoding identifiers.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_VideoSender]
    ) {
        for videoSender in layerSettings {
            let key = PublishOptions.VideoPublishOptions(
                id: Int(videoSender.publishOptionID),
                codec: VideoCodec(videoSender.codec)
            )
            guard
                let transceiver = transceiverStorage.get(for: key)
            else {
                log.debug(
                    """
                    We didn't apply publish quality change because transceiver 
                    not found for publishOptionID:\(videoSender.publishOptionID) and codec:\(VideoCodec(videoSender.codec)). 
                    Available transceivers: \(transceiverStorage.map { "publishOptionID:\($0.key.id), codec:\($0.key.codec)" })
                    """,
                    subsystems: .webRTC
                )
                continue
            }

            var hasChanges = false
            let params = transceiver
                .sender
                .parameters

            guard
                !params.encodings.isEmpty
            else {
                log.warning("Update publish quality, No suitable video encoding quality found", subsystems: .webRTC)
                return
            }

            let isUsingSVCCodec = {
                if let preferredCodec = params.codecs.first {
                    return VideoCodec(preferredCodec).isSVC
                } else {
                    return false
                }
            }()
            var updatedEncodings = [RTCRtpEncodingParameters]()

            for encoding in params.encodings {
                let layerSettings = isUsingSVCCodec
                    // for SVC, we only have one layer (q) and often rid is omitted
                    ? videoSender.layers.first
                    // for non-SVC, we need to find the layer by rid (simulcast)
                    : videoSender.layers.first(where: { $0.name == encoding.rid })

                // flip 'active' flag only when necessary
                if layerSettings?.active != encoding.isActive {
                    encoding.isActive = layerSettings?.active ?? false
                    hasChanges = true
                }

                // skip the rest of the settings if the layer is disabled or not found
                guard let layerSettings else {
                    updatedEncodings.append(encoding)
                    continue
                }

                if
                    layerSettings.scaleResolutionDownBy >= 1,
                    layerSettings.scaleResolutionDownBy != Float(truncating: encoding.scaleResolutionDownBy ?? 0)
                {
                    encoding.scaleResolutionDownBy = .init(value: layerSettings.scaleResolutionDownBy)
                    hasChanges = true
                }

                if
                    layerSettings.maxBitrate > 0,
                    layerSettings.maxBitrate != Int32(truncating: encoding.maxBitrateBps ?? 0)
                {
                    encoding.maxBitrateBps = .init(value: layerSettings.maxBitrate)
                    hasChanges = true
                }

                if
                    layerSettings.maxFramerate > 0,
                    layerSettings.maxFramerate != Int32(truncating: encoding.maxFramerate ?? 0)
                {
                    encoding.maxFramerate = .init(value: layerSettings.maxFramerate)
                    hasChanges = true
                }

                if
                    !layerSettings.scalabilityMode.isEmpty,
                    layerSettings.scalabilityMode != encoding.scalabilityMode
                {
                    encoding.scalabilityMode = layerSettings.scalabilityMode
                    hasChanges = true
                }

                updatedEncodings.append(encoding)
            }

            let activeLayers = videoSender
                .layers
                .filter { $0.active }
                .map {
                    let value = [
                        "name:\($0.name)",
                        "scaleResolutionDownBy:\($0.scaleResolutionDownBy)",
                        "maxBitrate:\($0.maxBitrate)",
                        "maxFramerate:\($0.maxFramerate)",
                        "scalabilityMode:\($0.scalabilityMode)"
                    ]
                    return "[\(value.joined(separator: ","))]"
                }

            guard hasChanges else {
                log.info(
                    "Update publish quality, no change: \(activeLayers.joined(separator: ","))",
                    subsystems: .webRTC
                )
                return
            }
            log.info(
                "Update publish quality for publishOptionID:\(videoSender.publishOptionID) codec:\(VideoCodec(videoSender.codec)), enabled rids: \(activeLayers.joined(separator: ","))",
                subsystems: .webRTC
            )
            params.encodings = updatedEncodings
            transceiver.sender.parameters = params
        }

        Task { @MainActor in
            do {
                try await videoCapturePolicy.updateCaptureQuality(
                    with: .init(layerSettings.map(\.name)),
                    for: videoCaptureSessionProvider.activeSession
                )
            } catch {
                log.error(error)
            }
        }
    }

    // MARK: - Camera Video

    /// Updates the camera position.
    ///
    /// - Parameter position: The new camera position.
    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await configureActiveVideoCaptureSession(
            position: position,
            track: primaryTrack
        )
    }

    /// Sets a video filter.
    ///
    /// - Parameter videoFilter: The video filter to apply.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        Task { [weak self] in
            await self?.capturer?.setVideoFilter(videoFilter)
        }.store(in: disposableBag, key: "\(#function)")
    }

    /// Zooms the camera by a given factor.
    ///
    /// - Parameter factor: The zoom factor.
    func zoom(by factor: CGFloat) async throws {
        try await capturer?.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point to focus on.
    func focus(at point: CGPoint) async throws {
        try await capturer?.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await capturer?.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await capturer?.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await capturer?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await capturer?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    // MARK: - Private helpers

    /// Configures the active video capture session.
    ///
    /// - Parameters:
    ///   - position: The desired camera position.
    ///   - track: The video track to configure.
    private func configureActiveVideoCaptureSession(
        position: AVCaptureDevice.Position,
        track: RTCVideoTrack
    ) async throws {
        if videoCaptureSessionProvider.activeSession == nil {
            let cameraCapturer = capturerFactory.buildCameraCapturer(
                source: track.source
            )
            capturer = cameraCapturer

            videoCaptureSessionProvider.activeSession = .init(
                position: position,
                device: nil,
                localTrack: track,
                capturer: cameraCapturer
            )
        } else if
            let activeSession = videoCaptureSessionProvider.activeSession,
            activeSession.device == nil,
            activeSession.position != position {
            videoCaptureSessionProvider.activeSession = .init(
                position: position,
                device: nil,
                localTrack: activeSession.localTrack,
                capturer: activeSession.capturer
            )
        } else if
            let activeSession = videoCaptureSessionProvider.activeSession,
            activeSession.position != position {
            // We are currently capturing
            let device = captureDeviceProvider.device(for: position)
            videoCaptureSessionProvider.activeSession = .init(
                position: position,
                device: device,
                localTrack: activeSession.localTrack,
                capturer: activeSession.capturer
            )
            try await activeSession.capturer.setCameraPosition(position)
        }
    }

    /// Starts the video capturing session.
    ///
    /// Configures the session with the highest resolution and frame rate based on publish options.
    private func startVideoCapturingSession() async throws {
        let capturingDimension = publishOptions
            .map(\.dimensions)
            .max(by: { $0.width < $1.width && $0.height < $1.height })
        let frameRate = publishOptions.map(\.frameRate).max()

        guard
            let activeSession = videoCaptureSessionProvider.activeSession,
            activeSession.device == nil,
            let device = captureDeviceProvider.device(for: activeSession.position),
            let capturingDimension,
            let frameRate
        else {
            log.debug(
                """
                Active video capture session hasn't been configured for capturing.
                    isActiveSessionAlive: \(videoCaptureSessionProvider.activeSession != nil) 
                    isCapturingDeviceAlive: \(videoCaptureSessionProvider.activeSession?.device != nil)
                    CapturingDimensions: \(capturingDimension ?? .zero)
                    FrameRate: \(frameRate ?? 0)
                """,
                subsystems: .webRTC
            )
            return
        }

        try await activeSession.capturer.startCapture(
            position: activeSession.position,
            dimensions: capturingDimension,
            frameRate: frameRate
        )
        videoCaptureSessionProvider.activeSession = .init(
            position: activeSession.position,
            device: device,
            localTrack: activeSession.localTrack,
            capturer: activeSession.capturer
        )

        log.debug(
            """
            Active video capture session started
                position: \(activeSession.position)
                device: \(device)
                track: \(activeSession.localTrack.trackId)
                capturer: \(Unmanaged.passUnretained(activeSession.capturer).toOpaque())
                dimensions: \(capturingDimension)
                frameRate: \(frameRate)
            """,
            subsystems: .webRTC
        )
    }

    /// Stops the video capturing session.
    ///
    /// Cleans up the active session and stops the capturer.
    private func stopVideoCapturingSession() async throws {
        guard
            let activeSession = videoCaptureSessionProvider.activeSession,
            activeSession.device != nil
        else {
            log.debug(
                """
                Active video capture session hasn't been configured for capturing.
                    isActiveSessionAlive: \(videoCaptureSessionProvider.activeSession != nil) 
                    isCapturingDeviceAlive: \(videoCaptureSessionProvider.activeSession?.device != nil)
                """,
                subsystems: .webRTC
            )
            return
        }
        try await activeSession.capturer.stopCapture()
        videoCaptureSessionProvider.activeSession = .init(
            position: activeSession.position,
            device: nil,
            localTrack: activeSession.localTrack,
            capturer: activeSession.capturer
        )

        log.debug(
            """
            Active video capture session stopped
                position: \(activeSession.position)
                track: \(activeSession.localTrack.trackId)
                capturer: \(activeSession.capturer)
            """,
            subsystems: .webRTC
        )
    }

    /// Adds or updates a transceiver for a video track.
    ///
    /// - Parameters:
    ///   - options: The publish options for the track.
    ///   - track: The video track to add or update.
    private func addOrUpdateTransceiver(
        for options: PublishOptions.VideoPublishOptions,
        with track: RTCVideoTrack
    ) {
        if let transceiver = transceiverStorage.get(for: options) {
            transceiver.sender.track = track
        } else {
            let transceiver = peerConnection.addTransceiver(
                trackType: .video,
                with: track,
                init: .init(
                    trackType: .video,
                    direction: .sendOnly,
                    streamIds: streamIds,
                    videoOptions: options
                )
            )
            transceiverStorage.set(transceiver, for: options)
        }
    }
}
