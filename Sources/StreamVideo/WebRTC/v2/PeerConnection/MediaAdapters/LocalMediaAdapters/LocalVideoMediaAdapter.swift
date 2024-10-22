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
            if sender == nil, settings.videoOn, let localTrack {
                setUpTransceiverIfRequired(localTrack)
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

                setUpTransceiverIfRequired(localTrack)
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
        with layerSettings: [Stream_Video_Sfu_Event_VideoLayerSetting]
    ) {
        guard
            let sender,
            !layerSettings.isEmpty
        else {
            return
        }

        var hasChanges = false
        let params = sender
            .sender
            .parameters

        guard
            !params.encodings.isEmpty
        else {
            log.warning("Update publish quality, No suitable video encoding quality found", subsystems: .webRTC)
            return
        }

        let isUsingSVCCodec = {
            if
                let preferredCodec = params.codecs.first,
                let videoCodec = VideoCodec(preferredCodec) {
                return videoCodec.isSVC
            } else {
                return false
            }
        }()
        var updatedEncodings = [RTCRtpEncodingParameters]()

        for encoding in params.encodings {
            let layerSettings = isUsingSVCCodec
                // for SVC, we only have one layer (q) and often rid is omitted
                ? layerSettings[0]
                // for non-SVC, we need to find the layer by rid (simulcast)
                : layerSettings.first(where: { $0.name == encoding.rid })

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

        let activeLayers = layerSettings
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
        sender.sender.parameters = params

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

    private func setUpTransceiverIfRequired(_ localTrack: RTCVideoTrack) {
        if sender == nil {
            sender = peerConnection.addTransceiver(
                with: localTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .video,
                    direction: .sendOnly,
                    streamIds: streamIds,
                    layers: videoOptions.videoLayers,
                    preferredVideoCodec: videoOptions.preferredVideoCodec
                )
            )
            sender?.codecPreferences = codecPreferences
        } else {
            sender?.sender.track = localTrack
        }
    }

    private var codecPreferences: [RTCRtpCodecCapability] {
        let supportedCodecs = peerConnectionFactory.supportedVideoCodecEncoding
        var result = [RTCRtpCodecCapability]()
        for supportedCodec in supportedCodecs {
            let codecInfo = RTCRtpCodecCapability()
            codecInfo.name = supportedCodec.name
            codecInfo.kind = .video
            codecInfo.parameters = supportedCodec.parameters
            if supportedCodec.name.lowercased() == videoOptions.preferredVideoCodec.rawValue {
                result.insert(codecInfo, at: 0)
            } else {
                result.append(codecInfo)
            }
        }
        return result
    }
}
