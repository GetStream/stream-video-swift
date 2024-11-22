//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@preconcurrency import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// A class that manages local video media for a call session.
final class LocalVideoMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    @Injected(\.videoCapturePolicy) private var videoCapturePolicy
    @Injected(\.captureDeviceProvider) private var captureDeviceProvider

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

    private var publishOptions: [PublishOptions.VideoPublishOptions]

    /// The factory for creating the capturer.
    private let capturerFactory: VideoCapturerProviding

    /// The stream identifiers for this video adapter.
    private let streamIds: [String]

    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.VideoPublishOptions>(for: .video)

    private let primaryTrack: RTCVideoTrack

    private let videoCaptureSessionProvider: VideoCaptureSessionProvider

    /// The video capturer.
    private var capturer: StreamVideoCapturer?

    /// A publisher that emits track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    private let disposableBag = DisposableBag()

    /// Initializes a new instance of the local video media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - videoOptions: The video options for the call.
    ///   - videoConfig: The video configuration for the call.
    ///   - publishOptions: TODO
    ///   - subject: A publisher that emits track events.
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
        primaryTrack = {
            let source = videoCaptureSessionProvider
                .activeSession?
                .localTrack
                .source ?? peerConnectionFactory.makeVideoSource(forScreenShare: false)
            return peerConnectionFactory.makeVideoTrack(source: source)
        }()
        primaryTrack.isEnabled = false
        videoCaptureSessionProvider
            .activeSession?
            .localTrack = primaryTrack
        streamIds = ["\(sessionID):video"]
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        Task { @MainActor [transceiverStorage] in
            transceiverStorage.removeAll()
        }

        log.debug(
            """
            Local videoTracks will be deallocated
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
        Task { @MainActor in
            guard
                !primaryTrack.isEnabled
            else {
                return
            }

            do {
                try await startVideoCapturingSession()
                primaryTrack.isEnabled = true

                publishOptions
                    .forEach {
                        addOrUpdateTransceiver(
                            for: $0,
                            with: primaryTrack.clone(from: peerConnectionFactory)
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
            } catch {
                log.error(error)
            }
        }
    }

    /// Stops publishing the local video track.
    func unpublish() {
        Task { @MainActor [weak self] in
            do {
                guard
                    let self,
                    primaryTrack.isEnabled
                else {
                    return
                }

                primaryTrack.isEnabled = false

                transceiverStorage
                    .forEach { $0.value.sender.track?.isEnabled = false }

                try await stopVideoCapturingSession()

                log.debug(
                    """
                    Local videoTracks are now unpublished:
                        primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                        clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                    """,
                    subsystems: .webRTC
                )
            } catch {
                log.error(error, subsystems: .webRTC)
            }
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

    func trackInfo() -> [Stream_Video_Sfu_Models_TrackInfo] {
        transceiverStorage
            .filter { $0.value.sender.track != nil }
            .compactMap { publishOptions, transceiver in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .video
                trackInfo.trackID = transceiver.sender.track?.trackId ?? ""
                trackInfo.layers = transceiver
                    .sender
                    .parameters
                    .encodings
                    .map { Stream_Video_Sfu_Models_VideoLayer($0, publishOptions: publishOptions) }
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
            guard
                let codec = VideoCodec(rawValue: videoSender.codec.name),
                let transceiver = transceiverStorage.get(for: PublishOptions.VideoPublishOptions(
                    id: Int(videoSender.publishOptionID),
                    codec: codec
                ))
            else {
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
                "Update publish quality, enabled rids: \(activeLayers.joined(separator: ","))",
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
                capturer: \(activeSession.capturer)
            """,
            subsystems: .webRTC
        )
    }

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
