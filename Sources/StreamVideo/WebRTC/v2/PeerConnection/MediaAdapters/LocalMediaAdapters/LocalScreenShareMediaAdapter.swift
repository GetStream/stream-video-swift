//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class LocalScreenShareMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private var sfuAdapter: SFUAdapter
    private let videoOptions: VideoOptions
    private let videoConfig: VideoConfig
    private let screenShareSessionProvider: ScreenShareSessionProvider

    private(set) var localTrack: RTCVideoTrack?
    private var screenSharingType: ScreensharingType?
    private var capturer: VideoCapturing?
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
        subject: PassthroughSubject<TrackEvent, Never>,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.videoOptions = videoOptions
        self.videoConfig = videoConfig
        self.subject = subject
        self.screenShareSessionProvider = screenShareSessionProvider

        localTrack = screenShareSessionProvider.activeSession?.localTrack
        capturer = screenShareSessionProvider.activeSession?.capturer
        screenSharingType = screenShareSessionProvider.activeSession?.screenSharingType
    }

    deinit {
        sender?.sender.track = nil
    }

    // MARK: - LocalMediaManaging

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }

    func publish() {
        guard
            let localTrack,
            let screenSharingType,
            let capturer,
            localTrack.isEnabled == false || sender == nil
        else {
            return
        }

        if sender == nil {
            sender = peerConnection.addTransceiver(
                with: localTrack,
                init: RTCRtpTransceiverInit(
                    trackType: .screenshare,
                    direction: .sendOnly,
                    streamIds: ["\(sessionID)-screenshare-\(screenSharingType)"],
                    codecs: [VideoCodec.screenshare]
                )
            )
        } else {
            sender?.sender.track = localTrack
        }
        Task {
            do {
                try await capturer.startCapture(device: nil)
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
        localTrack.isEnabled = true
        log.debug("Local screenShareTrack trackId:\(localTrack.trackId) is now published.")
    }

    func unpublish() {
        guard let sender, let localTrack else { return }
        Task {
            do {
                try await capturer?.stopCapture()
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
        sender.sender.track = nil
        localTrack.isEnabled = false
        log.debug(
            """
            Local screenShareTrack is now unpublished
            trackId: \(localTrack.trackId)
            screenSharingType: \(String(describing: screenSharingType))
            """,
            subsystems: .webRTC
        )
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        /* No-op */
    }

    // MARK: - Screensharing

    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability],
        removeAllScreenSharingStreams: @escaping () -> Void
    ) async throws {
        let hasScreenShare = ownCapabilities.contains(.screenshare)

        guard hasScreenShare else { return }

        if type != screenSharingType {
            localTrack = nil
            sender?.sender.track = nil
            sender?.stopInternal()
            sender = nil
        }

        if localTrack == nil {
            try await makeVideoTrack(type)
        }

        try await sfuAdapter.updateTrackMuteState(
            .screenShare,
            isMuted: false,
            for: sessionID
        )

        publish()

        if let localTrack, let screenSharingType, let capturer {
            screenShareSessionProvider.activeSession = .init(
                localTrack: localTrack,
                screenSharingType: screenSharingType,
                capturer: capturer
            )
        }
    }

    func stopScreenSharing() async throws {
        try await sfuAdapter.updateTrackMuteState(
            .screenShare,
            isMuted: true,
            for: sessionID
        )

        unpublish()

        screenShareSessionProvider.activeSession = nil
    }

    // MARK: - Private helpers

    private func makeVideoTrack(
        _ screenSharingType: ScreensharingType
    ) async throws {
        let videoSource = peerConnectionFactory
            .makeVideoSource(forScreenShare: true)
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        self.screenSharingType = screenSharingType
        localTrack = videoTrack
        videoTrack.isEnabled = false

        log.debug(
            """
            ScreenShareTrack generated
            address:\(Unmanaged.passUnretained(videoTrack).toOpaque())
            trackId:\(videoTrack.trackId)
            mid: \(sender?.mid ?? "-")
            screenSharingType: \(screenSharingType)
            """
        )

        subject.send(
            .added(
                id: sessionID,
                trackType: .screenshare,
                track: videoTrack
            )
        )

        switch screenSharingType {
        case .inApp:
            capturer = ScreenshareCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
        case .broadcast:
            capturer = BroadcastScreenCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
        }
    }
}

extension RTCVideoTrack: @unchecked Sendable {}
