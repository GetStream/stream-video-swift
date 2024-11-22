//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    private let peerConnection: StreamRTCPeerConnectionProtocol
    /// Factory for creating peer connection related objects.
    private let peerConnectionFactory: PeerConnectionFactory
    /// Adapter for communicating with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    private var publishOptions: [PublishOptions.VideoPublishOptions]
    /// The factory for creating the capturer.
    private let capturerFactory: VideoCapturerProviding
    /// Provider for screen sharing session information.
    private let screenShareSessionProvider: ScreenShareSessionProvider
    /// The type of screen sharing currently active.

    private let primaryTrack: RTCVideoTrack

    /// The screenshare capturer.
    private var capturer: StreamVideoCapturer?

    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.VideoPublishOptions>(for: .screenshare)

    /// A subject for publishing track-related events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Initializes a new instance of the LocalScreenShareMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The peer connection used for WebRTC communication.
    ///   - peerConnectionFactory: Factory for creating peer connection related objects.
    ///   - sfuAdapter: Adapter for communicating with the Selective Forwarding Unit (SFU).
    ///   - subject: A subject for publishing track-related events.
    ///   - screenShareSessionProvider: Provider for screen sharing session information.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.VideoPublishOptions],
        subject: PassthroughSubject<TrackEvent, Never>,
        screenShareSessionProvider: ScreenShareSessionProvider,
        capturerFactory: VideoCapturerProviding = StreamVideoCapturerFactory()
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.publishOptions = publishOptions
        self.subject = subject
        self.screenShareSessionProvider = screenShareSessionProvider
        self.capturerFactory = capturerFactory
        primaryTrack = {
            let source = screenShareSessionProvider
                .activeSession?
                .localTrack
                .source ?? peerConnectionFactory.makeVideoSource(forScreenShare: true)
            return peerConnectionFactory.makeVideoTrack(source: source)
        }()
        primaryTrack.isEnabled = false
        screenShareSessionProvider
            .activeSession?
            .localTrack = primaryTrack
    }

    /// Cleans up resources when the instance is being deallocated.
    deinit {
        Task { @MainActor [transceiverStorage] in
            transceiverStorage.removeAll()
        }

        log.debug(
            """
            Local screenShareTracks will be deallocated
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )
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
        subject.send(
            .added(
                id: sessionID,
                trackType: .screenshare,
                track: primaryTrack
            )
        )
    }

    /// Publishes the local screen sharing track to the peer connection.
    func publish() {
        Task { @MainActor in
            guard
                !primaryTrack.isEnabled,
                let activeSession = screenShareSessionProvider.activeSession
            else {
                return
            }

            do {
                try await startScreenShareCapturingSession()
                primaryTrack.isEnabled = true

                publishOptions
                    .forEach {
                        addOrUpdateTransceiver(
                            for: $0,
                            with: primaryTrack.clone(from: peerConnectionFactory),
                            screenSharingType: activeSession.screenSharingType
                        )
                    }

                log.debug(
                    """
                    Local screenShareTracks are now published
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

    /// Unpublishes the local screen sharing track from the peer connection.
    func unpublish() {
        Task { @MainActor [weak self] in
            do {
                guard
                    let self,
                    primaryTrack.isEnabled,
                    screenShareSessionProvider.activeSession != nil
                else {
                    return
                }

                primaryTrack.isEnabled = false

                transceiverStorage
                    .forEach { $0.value.sender.track?.isEnabled = false }

                try await stopScreenShareCapturingSession()

                log.debug(
                    """
                    Local screenShareTracks are now unpublished:
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

    /// Updates the call settings.
    ///
    /// - Parameter settings: The new call settings to apply.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        /* No-op */
    }

    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        guard
            primaryTrack.isEnabled,
            let activeSession = screenShareSessionProvider.activeSession
        else { return }

        self.publishOptions = publishOptions.screenShare

        for publishOption in self.publishOptions {
            addOrUpdateTransceiver(
                for: publishOption,
                with: primaryTrack.clone(from: peerConnectionFactory),
                screenSharingType: activeSession.screenSharingType
            )
        }

        let activePublishOptions = Set(self.publishOptions)

        transceiverStorage
            .filter { !activePublishOptions.contains($0.key) }
            .forEach { $0.value.sender.track = nil }

        log.debug(
            """
            Local screenShareTracks updated with:
                PublishOptions:
                    \(self.publishOptions.map { "\($0)" }.joined(separator: "\n"))
                
                TransceiverStorage:
                    \(transceiverStorage)
            """,
            subsystems: .webRTC
        )
    }

    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_VideoSender]
    ) {
        /* No-op */
    }

    func trackInfo() -> [Stream_Video_Sfu_Models_TrackInfo] {
        transceiverStorage
            .filter { $0.value.sender.track != nil }
            .compactMap { publishOptions, transceiver in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .screenShare
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
        guard ownCapabilities.contains(.screenshare) else {
            try await stopScreenShareCapturingSession()
            return
        }

        guard screenShareSessionProvider.activeSession == nil || !primaryTrack.isEnabled else {
            return
        }

        try await configureActiveScreenShareSession(
            screenSharingType: type,
            track: primaryTrack
        )

        try await sfuAdapter.updateTrackMuteState(
            .screenShare,
            isMuted: false,
            for: sessionID
        )

        publish()
    }

    /// Stops the current screen sharing session.
    func stopScreenSharing() async throws {
        try await sfuAdapter.updateTrackMuteState(
            .screenShare,
            isMuted: true,
            for: sessionID
        )

        unpublish()
    }

    // MARK: - Private helpers

    private func addOrUpdateTransceiver(
        for options: PublishOptions.VideoPublishOptions,
        with track: RTCVideoTrack,
        screenSharingType: ScreensharingType
    ) {
        if let transceiver = transceiverStorage.get(for: options) {
            transceiver.sender.track = track
        } else {
            let transceiver = peerConnection.addTransceiver(
                trackType: .screenshare,
                with: track,
                init: .init(
                    trackType: .screenshare,
                    direction: .sendOnly,
                    streamIds: ["\(sessionID)-screenshare-\(screenSharingType)"],
                    videoOptions: options
                )
            )
            transceiverStorage.set(transceiver, for: options)
        }
    }

    private func configureActiveScreenShareSession(
        screenSharingType: ScreensharingType,
        track: RTCVideoTrack
    ) async throws {
        if screenShareSessionProvider.activeSession == nil {
            let videoCapturer = capturerFactory.buildScreenCapturer(
                screenSharingType,
                source: track.source
            )
            capturer = videoCapturer

            screenShareSessionProvider.activeSession = .init(
                localTrack: track,
                screenSharingType: screenSharingType,
                capturer: videoCapturer
            )
        } else if
            let activeSession = screenShareSessionProvider.activeSession,
            activeSession.screenSharingType != screenSharingType {
            try await stopScreenShareCapturingSession()

            let videoCapturer = capturerFactory.buildScreenCapturer(
                screenSharingType,
                source: track.source
            )
            capturer = videoCapturer

            screenShareSessionProvider.activeSession = .init(
                localTrack: track,
                screenSharingType: screenSharingType,
                capturer: videoCapturer
            )
        }
    }

    private func startScreenShareCapturingSession() async throws {
        let capturingDimension = publishOptions
            .map(\.dimensions)
            .max(by: { $0.width < $1.width && $0.height < $1.height })
        let frameRate = publishOptions.map(\.frameRate).max()

        guard
            let activeSession = screenShareSessionProvider.activeSession,
            let capturingDimension,
            let frameRate
        else {
            log.debug(
                """
                Active screenShare capture session hasn't been configured for capturing.
                    isActiveSessionAlive: \(screenShareSessionProvider.activeSession != nil) 
                    CapturingDimensions: \(capturingDimension ?? .zero)
                    FrameRate: \(frameRate ?? 0)
                """,
                subsystems: .webRTC
            )
            return
        }

        try await activeSession.capturer.startCapture(
            dimensions: capturingDimension,
            frameRate: frameRate
        )

        log.debug(
            """
            Active screenShare capture session started
                capturingDimension: \(capturingDimension)
                frameRate: \(frameRate)
                track: \(activeSession.localTrack.trackId)
                capturer: \(activeSession.capturer)
            """,
            subsystems: .webRTC
        )
    }

    private func stopScreenShareCapturingSession() async throws {
        guard
            let activeSession = screenShareSessionProvider.activeSession
        else {
            log.debug(
                """
                Active screenShare capture session hasn't been configured for capturing.
                    isActiveSessionAlive: \(screenShareSessionProvider.activeSession != nil) 
                """,
                subsystems: .webRTC
            )
            return
        }
        try await activeSession.capturer.stopCapture()
        screenShareSessionProvider.activeSession = nil

        log.debug(
            """
            Active screenShare capture session stopped
                track: \(activeSession.localTrack.trackId)
                capturer: \(activeSession.capturer)
            """,
            subsystems: .webRTC
        )
    }
}
