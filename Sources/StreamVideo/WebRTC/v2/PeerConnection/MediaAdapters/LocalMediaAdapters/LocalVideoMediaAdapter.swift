//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class LocalVideoMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private var sfuAdapter: SFUAdapter
    private let videoOptions: VideoOptions
    private let videoConfig: VideoConfig
    private let streamIds: [String]

    private(set) var localTrack: RTCVideoTrack?
    private var capturer: CameraVideoCapturing?
    private var sender: RTCRtpTransceiver?

    var mid: String? { sender?.mid }

    let subject: PassthroughSubject<TrackEvent, Never>

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.videoOptions = videoOptions
        self.videoConfig = videoConfig
        self.subject = subject
        streamIds = ["\(sessionID):video"]
    }

    deinit {
        Task { [capturer] in try? await capturer?.stopCapture() }
        localTrack?.isEnabled = false
        sender?.sender.track = nil
        if let localTrack {
            log.debug(
                """
                Local videoTrack will be deallocated
                trackId:\(localTrack.trackId)
                isEnabled:\(localTrack.isEnabled)
                """
            )
        }
    }

    // MARK: - LocalMediaManaging

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
            localTrack?.isEnabled = false
            Task { [weak self] in
                do {
                    try await self?.capturer?.stopCapture()
                } catch {
                    log.error(error)
                }
            }
        }
    }

    func publish() {
        guard
            let localTrack,
            localTrack.isEnabled == false || sender == nil
        else {
            return
        }

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
    }

    func unpublish() {
        guard let sender, let localTrack else { return }
        sender.sender.track = nil
        localTrack.isEnabled = false
        log.debug("Local videoTrack trackId:\(localTrack.trackId) is now unpublished.")
    }

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

    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        guard
            let capturer
        else {
            log.debug("Cannot update cameraPosition as track isn't being captured.")
            return
        }
        try await capturer.setCameraPosition(position)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        capturer?.setVideoFilter(videoFilter)
    }

    func zoom(by factor: CGFloat) throws {
        try (capturer as? VideoCapturer)?.zoom(by: factor)
    }

    func focus(at point: CGPoint) throws {
        try (capturer as? VideoCapturer)?.focus(at: point)
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try (capturer as? VideoCapturer)?.addVideoOutput(videoOutput)
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try (capturer as? VideoCapturer)?.removeVideoOutput(videoOutput)
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try (capturer as? VideoCapturer)?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try (capturer as? VideoCapturer)?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        guard let sender, !activeEncodings.isEmpty else {
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
                updatedEncodings.append(encoding)
            case (false, false):
                updatedEncodings.append(encoding)
            default:
                hasChanges = true
                encoding.isActive = shouldEnable
                updatedEncodings.append(encoding)
            }
        }

        guard hasChanges else {
            return
        }
        params.encodings = updatedEncodings
        sender.sender.parameters = params
    }

    // MARK: - Private helpers

    private func makeVideoTrack(
        _ position: AVCaptureDevice.Position
    ) async throws {
        let videoSource = peerConnectionFactory
            .makeVideoSource(forScreenShare: false)
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        localTrack = videoTrack
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

        try await capturer?.stopCapture()
        let cameraCapturer = VideoCapturer(
            videoSource: videoSource,
            videoOptions: videoOptions,
            videoFilters: videoConfig.videoFilters
        )
        capturer = cameraCapturer

        let device = cameraCapturer.capturingDevice(for: position)
        try await cameraCapturer.startCapture(device: device)
    }
}
