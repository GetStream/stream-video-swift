//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that adapts local screen sharing media for use in a streaming context.
///
/// This class manages the local screen sharing track, handling its publication,
/// unpublication, and interaction with the peer connection.
final class LocalScreenShareMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String
    /// The peer connection used for WebRTC communication.
    private let peerConnection: StreamRTCPeerConnection
    /// Factory for creating peer connection related objects.
    private let peerConnectionFactory: PeerConnectionFactory
    /// Adapter for communicating with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter
    /// Options for configuring video behavior.
    private let videoOptions: VideoOptions
    /// Configuration settings for video.
    private let videoConfig: VideoConfig
    /// Provider for screen sharing session information.
    private let screenShareSessionProvider: ScreenShareSessionProvider

    /// The local video track used for screen sharing.
    private(set) var localTrack: RTCVideoTrack?
    /// The type of screen sharing currently active.
    private var screenSharingType: ScreensharingType?
    /// The video capturer used to capture screen content.
    private var capturer: VideoCapturing?
    /// The RTP transceiver used to send the screen sharing track.
    private var sender: RTCRtpTransceiver?

    /// The media stream identifier (mid) of the sender.
    var mid: String? { sender?.mid }

    /// A subject for publishing track-related events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Initializes a new instance of the LocalScreenShareMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The peer connection used for WebRTC communication.
    ///   - peerConnectionFactory: Factory for creating peer connection related objects.
    ///   - sfuAdapter: Adapter for communicating with the Selective Forwarding Unit (SFU).
    ///   - videoOptions: Options for configuring video behavior.
    ///   - videoConfig: Configuration settings for video.
    ///   - subject: A subject for publishing track-related events.
    ///   - screenShareSessionProvider: Provider for screen sharing session information.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnection,
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

    /// Cleans up resources when the instance is being deallocated.
    deinit {
        sender?.sender.track = nil
    }

    // MARK: - LocalMediaManaging

    /// Sets up the local media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to apply.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }

    /// Publishes the local screen sharing track to the peer connection.
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

    /// Unpublishes the local screen sharing track from the peer connection.
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

    /// Updates the call settings.
    ///
    /// - Parameter settings: The new call settings to apply.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        /* No-op */
    }

    // MARK: - Screensharing

    /// Begins screen sharing of the specified type.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to begin.
    ///   - ownCapabilities: The capabilities of the local participant.
    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
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

    /// Stops the current screen sharing session.
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

    /// Creates a new video track for screen sharing.
    ///
    /// - Parameter screenSharingType: The type of screen sharing to set up.
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
