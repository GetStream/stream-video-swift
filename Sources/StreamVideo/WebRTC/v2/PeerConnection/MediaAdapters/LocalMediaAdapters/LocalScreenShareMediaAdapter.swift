//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that adapts local screen sharing media for use in a streaming context.
///
/// This class manages the lifecycle of local screen sharing, including its
/// publication, unpublication, and interaction with the WebRTC peer connection.
/// It integrates with WebRTC components and handles screen sharing sessions
/// dynamically based on user actions.
final class LocalScreenShareMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The peer connection used for WebRTC communication.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// Factory for creating WebRTC-related objects such as tracks and sources.
    private let peerConnectionFactory: PeerConnectionFactory

    /// Adapter for interacting with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    /// The publishing options for video tracks, including dimensions and frame rate.
    private var publishOptions: [PublishOptions.VideoPublishOptions]

    /// Factory for creating video capturers.
    private let capturerFactory: VideoCapturerProviding

    /// Provider for managing screen sharing sessions.
    private let screenShareSessionProvider: ScreenShareSessionProvider

    /// The screen sharing capturer for capturing screen frames.
    private var capturer: StreamVideoCapturing?

    /// Storage for managing transceivers associated with the screen sharing session.
    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.VideoPublishOptions>(for: .screenshare)

    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private let audioDeviceModule: AudioDeviceModule

    /// The primary video track used for screen sharing.
    let primaryTrack: RTCVideoTrack

    /// A publisher that emits events related to the screen sharing track.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// We only want to register (send our primary track to the subject) only when we are about to publish
    /// for the first time. The property help us keep track of that.
    private var hasRegisteredPrimaryTrack: Bool = false

    /// Initializes a new instance of the LocalScreenShareMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The peer connection used for WebRTC communication.
    ///   - peerConnectionFactory: Factory for creating WebRTC-related objects.
    ///   - sfuAdapter: Adapter for interacting with the SFU.
    ///   - publishOptions: Initial publishing options for video tracks.
    ///   - subject: A subject for publishing track-related events.
    ///   - screenShareSessionProvider: Provider for managing screen sharing sessions.
    ///   - capturerFactory: Factory for creating video capturers. Defaults to
    ///     `StreamVideoCapturerFactory`.
    ///   - audioDeviceModule: The audio device module used for screen share audio.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.VideoPublishOptions],
        subject: PassthroughSubject<TrackEvent, Never>,
        screenShareSessionProvider: ScreenShareSessionProvider,
        capturerFactory: VideoCapturerProviding = StreamVideoCapturerFactory(),
        audioDeviceModule: AudioDeviceModule
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.publishOptions = publishOptions
        self.subject = subject
        self.screenShareSessionProvider = screenShareSessionProvider
        self.capturerFactory = capturerFactory
        self.audioDeviceModule = audioDeviceModule

        // Initialize the primary track, using the existing session's local track if available.
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
    ///
    /// This method removes all transceivers from storage and logs deallocation details.
    deinit {
        transceiverStorage.removeAll()
        log.debug(
            """
            Local screenShareTracks will be deallocated
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
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
        /* No-op */
    }

    /// Publishes the local screen sharing track to the peer connection.
    ///
    /// This method enables the primary screen sharing track and creates
    /// transceivers based on the specified publish options.
    func publish() {
        processingQueue.addTaskOperation { @MainActor [weak self] in
            guard
                let self,
                !primaryTrack.isEnabled,
                let activeSession = screenShareSessionProvider.activeSession
            else {
                return
            }

            primaryTrack.isEnabled = true

            publishOptions.forEach {
                self.addTransceiverIfRequired(
                    for: $0,
                    with: self.primaryTrack.clone(from: self.peerConnectionFactory),
                    screenSharingType: activeSession.screenSharingType
                )
            }

            let activePublishOptions = Set(self.publishOptions)

            transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }

            log.debug(
                """
                Local screenShareTracks are now published
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Unpublishes the local screen sharing track from the peer connection.
    ///
    /// This method disables the primary screen sharing track and all associated
    /// transceivers, and stops the screen sharing capturing session.
    func unpublish() {
        processingQueue.addTaskOperation { @MainActor [weak self] in
            do {
                guard
                    let self,
                    primaryTrack.isEnabled,
                    screenShareSessionProvider.activeSession != nil
                else {
                    return
                }

                primaryTrack.isEnabled = false

                transceiverStorage.forEach { $0.value.track.isEnabled = false }

                try await stopScreenShareCapturingSession()

                log.debug(
                    """
                    Local screenShareTracks are now unpublished:
                        primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                        clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
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

    /// Updates the publishing options for the screen sharing track.
    ///
    /// - Parameter publishOptions: The new publishing options to apply.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else { return }

            self.publishOptions = publishOptions.screenShare

            guard
                primaryTrack.isEnabled,
                let activeSession = screenShareSessionProvider.activeSession
            else { return }

            for publishOption in self.publishOptions {
                addTransceiverIfRequired(
                    for: publishOption,
                    with: primaryTrack.clone(from: peerConnectionFactory),
                    screenSharingType: activeSession.screenSharingType
                )
            }

            let activePublishOptions = Set(self.publishOptions)

            transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }

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
    }

    /// Adjusts the publishing quality of the screen sharing track.
    ///
    /// - Parameter layerSettings: The new quality settings for video layers.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_VideoSender]
    ) {
        /* No-op */
    }

    /// Retrieves information about the active screen sharing tracks.
    ///
    /// - Returns: An array of track information including track ID, layers,
    ///   and mute state.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        let transceivers = {
            switch collectionType {
            case .allAvailable:
                return transceiverStorage
                    .map { ($0, $1.transceiver, $1.track) }
            case .lastPublishOptions:
                return publishOptions
                    .compactMap {
                        if
                            let entry = transceiverStorage.get(for: $0),
                            entry.transceiver.sender.track != nil {
                            return ($0, entry.transceiver, entry.track)
                        } else {
                            return nil
                        }
                    }
            }
        }()

        return transceivers
            .compactMap { publishOptions, transceiver, track in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .screenShare
                trackInfo.trackID = track.trackId
                trackInfo.layers = publishOptions.buildLayers(for: .screenshare)
                trackInfo.mid = transceiver.mid
                trackInfo.muted = !track.isEnabled
                trackInfo.codec = .init(publishOptions.codec)
                trackInfo.codec.fmtp = publishOptions.fmtp
                trackInfo.publishOptionID = Int32(publishOptions.id)
                return trackInfo
            }
    }

    // MARK: - Screensharing

    /// Begins a screen sharing session of the specified type.
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
        guard ownCapabilities.contains(.screenshare) else {
            try await stopScreenShareCapturingSession()
            return
        }

        try await configureActiveScreenShareSession(
            screenSharingType: type,
            track: primaryTrack,
            includeAudio: includeAudio
        )

        try await startScreenShareCapturingSession()

        guard screenShareSessionProvider.activeSession != nil else {
            return
        }

        registerPrimaryTrackIfPossible()
        
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

    // MARK: - Private Helpers

    /// Adds or updates a transceiver for a given track and publishing option.
    ///
    /// - Parameters:
    ///   - options: The publishing options for the track.
    ///   - track: The video track to add or update.
    ///   - screenSharingType: The type of screen sharing.
    private func addTransceiverIfRequired(
        for options: PublishOptions.VideoPublishOptions,
        with track: RTCVideoTrack,
        screenSharingType: ScreensharingType
    ) {
        guard !transceiverStorage.contains(key: options) else {
            return
        }

        guard
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
        else {
            log.warning("Unable to create transceiver for options:\(options).", subsystems: .webRTC)
            return
        }
        transceiverStorage.set(transceiver, track: track, for: options)
    }

    /// Configures the active screen sharing session with the given type and track.
    ///
    /// - Parameters:
    ///   - screenSharingType: The type of screen sharing.
    ///   - track: The video track to use for the session.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    private func configureActiveScreenShareSession(
        screenSharingType: ScreensharingType,
        track: RTCVideoTrack,
        includeAudio: Bool
    ) async throws {
        if screenShareSessionProvider.activeSession == nil {
            let videoCapturer = capturerFactory.buildScreenCapturer(
                screenSharingType,
                source: track.source,
                audioDeviceModule: audioDeviceModule,
                includeAudio: includeAudio
            )
            capturer = videoCapturer

            screenShareSessionProvider.activeSession = .init(
                localTrack: track,
                screenSharingType: screenSharingType,
                capturer: videoCapturer,
                includeAudio: includeAudio
            )
        } else if
            let activeSession = screenShareSessionProvider.activeSession,
            activeSession.screenSharingType != screenSharingType {
            try await stopScreenShareCapturingSession()

            let videoCapturer = capturerFactory.buildScreenCapturer(
                screenSharingType,
                source: track.source,
                audioDeviceModule: audioDeviceModule,
                includeAudio: includeAudio
            )
            capturer = videoCapturer

            screenShareSessionProvider.activeSession = .init(
                localTrack: track,
                screenSharingType: screenSharingType,
                capturer: videoCapturer,
                includeAudio: includeAudio
            )
        }
    }

    /// Starts the screen sharing capturing session.
    ///
    /// Configures the session with the highest specified dimensions and frame rate.
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
            position: .front, // It doesn't matter
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

    /// Stops the current screen sharing capturing session.
    ///
    /// Cleans up the active session and stops the associated capturer.
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

    /// We only want to register the primaryTrack only when we are about to publish for the first time.
    private func registerPrimaryTrackIfPossible() {
        guard !hasRegisteredPrimaryTrack else {
            return
        }

        subject.send(
            .added(
                id: sessionID,
                trackType: .screenshare,
                track: primaryTrack
            )
        )
        hasRegisteredPrimaryTrack = true
    }
}
