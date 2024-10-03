//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// An actor class that handles WebRTC state management and media tracks for a
/// video call. This class manages the connection setup, track handling, and
/// participants, including their media settings, capabilities, and track
/// updates.
actor WebRTCStateAdapter: ObservableObject {

    /// Enum representing different types of media tracks.
    enum TrackEntry {
        case audio(id: String, track: RTCAudioTrack)
        case video(id: String, track: RTCVideoTrack)
        case screenShare(id: String, track: RTCVideoTrack)

        /// Returns the ID associated with the track entry.
        var id: String {
            switch self {
            case let .audio(id, _):
                return id
            case let .video(id, _):
                return id
            case let .screenShare(id, _):
                return id
            }
        }
    }

    // Properties for user, API key, call ID, video configuration, and factories.
    let user: User
    let apiKey: String
    let callCid: String
    let videoConfig: VideoConfig
    let peerConnectionFactory: PeerConnectionFactory
    let screenShareSessionProvider: ScreenShareSessionProvider

    /// Published properties that represent different parts of the WebRTC state.
    @Published private(set) var sessionID: String = ""
    @Published private(set) var token: String = ""
    @Published private(set) var callSettings: CallSettings = .init()
    @Published private(set) var audioSettings: AudioSettings = .init()

    /// Published property to track video options and update them.
    @Published private(set) var videoOptions: VideoOptions = .init() {
        didSet { didUpdate(videoOptions: videoOptions) }
    }

    @Published private(set) var connectOptions: ConnectOptions = .init(iceServers: [])
    @Published private(set) var ownCapabilities: Set<OwnCapability> = []
    @Published private(set) var sfuAdapter: SFUAdapter?
    @Published private(set) var publisher: RTCPeerConnectionCoordinator?
    @Published private(set) var subscriber: RTCPeerConnectionCoordinator?
    @Published private(set) var statsReporter: WebRTCStatsReporter?
    @Published private(set) var participants: [String: CallParticipant] = [:]
    @Published private(set) var participantsCount: UInt32 = 0
    @Published private(set) var anonymousCount: UInt32 = 0
    @Published private(set) var participantPins: [PinInfo] = []

    // Various private and internal properties.
    private(set) var initialCallSettings: CallSettings?
    private var audioTracks: [String: RTCAudioTrack] = [:]
    private var videoTracks: [String: RTCVideoTrack] = [:]
    private var screenShareTracks: [String: RTCVideoTrack] = [:]
    private var videoFilter: VideoFilter?

    private let rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding
    private let audioSession: AudioSession = .init()
    private let disposableBag = DisposableBag()
    private let peerConnectionsDisposableBag = DisposableBag()

    /// Subject to handle participant updates.
    private(set) lazy var participantsUpdateSubject = PassthroughSubject<[String: CallParticipant], Never>()

    /// Initializes the WebRTC state adapter with user details and connection
    /// configurations.
    ///
    /// - Parameters:
    ///   - user: The user participating in the call.
    ///   - apiKey: The API key for authenticating WebRTC calls.
    ///   - callCid: The call identifier (callCid).
    ///   - videoConfig: Configuration for video settings.
    ///   - rtcPeerConnectionCoordinatorFactory: Factory for peer connection
    ///     creation.
    ///   - screenShareSessionProvider: Provides sessions for screen sharing.
    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding,
        screenShareSessionProvider: ScreenShareSessionProvider = .init()
    ) {
        self.user = user
        self.apiKey = apiKey
        self.callCid = callCid
        self.videoConfig = videoConfig
        self.peerConnectionFactory = PeerConnectionFactory.build(
            audioProcessingModule: videoConfig.audioProcessingModule
        )
        self.rtcPeerConnectionCoordinatorFactory = rtcPeerConnectionCoordinatorFactory
        self.screenShareSessionProvider = screenShareSessionProvider
        let sessionID = UUID().uuidString

        Task { await set(sessionID: sessionID) }
    }

    /// Sets the session ID.
    func set(sessionID value: String) { self.sessionID = value }

    /// Sets the call settings.
    func set(callSettings value: CallSettings) { self.callSettings = value }

    /// Sets the initial call settings.
    func set(initialCallSettings value: CallSettings?) { self.initialCallSettings = value }

    /// Sets the audio settings.
    func set(audioSettings value: AudioSettings) { self.audioSettings = value }

    /// Sets the video options.
    func set(videoOptions value: VideoOptions) { self.videoOptions = value }

    /// Sets the connection options.
    func set(connectOptions value: ConnectOptions) { self.connectOptions = value }

    /// Sets the own capabilities of the current user.
    func set(ownCapabilities value: Set<OwnCapability>) { self.ownCapabilities = value }

    /// Sets the WebRTC stats reporter.
    func set(statsReporter value: WebRTCStatsReporter) {
        self.statsReporter = value
    }

    /// Sets the SFU (Selective Forwarding Unit) adapter and updates the stats
    /// reporter.
    func set(sfuAdapter value: SFUAdapter?) {
        self.sfuAdapter = value
        statsReporter?.sfuAdapter = sfuAdapter
    }

    /// Sets the number of participants in the call.
    func set(participantsCount value: UInt32) { self.participantsCount = value }

    /// Sets the anonymous participant count.
    func set(anonymousCount value: UInt32) { self.anonymousCount = value }

    /// Sets the participant pins.
    func set(participantPins value: [PinInfo]) { self.participantPins = value }

    /// Sets the token for the session.
    func set(token value: String) { self.token = value }

    /// Sets the video filter and applies it to the publisher.
    func set(videoFilter value: VideoFilter?) {
        videoFilter = value
        publisher?.setVideoFilter(value)
    }

    // MARK: - Session Management

    /// Refreshes the session by setting a new session ID.
    func refreshSession() {
        set(sessionID: UUID().uuidString)
    }

    /// Configures the peer connections for the session.
    ///
    /// - Throws: Throws an error if the SFU adapter is not set or other
    ///   connection setup fails.
    func configurePeerConnections() async throws {
        guard let sfuAdapter = sfuAdapter else {
            throw ClientError("SFUAdapter hasn't been created.")
        }

        log.debug(
            """
            Setting up PeerConnections with
            sessionId: \(sessionID)
            sfuAdapter: \(sfuAdapter.hostname)
            callSettings
                audioOn: \(callSettings.audioOn)
                videoOn: \(callSettings.videoOn)
                cameraPosition: \(callSettings.cameraPosition)
            """,
            subsystems: .webRTC
        )

        peerConnectionsDisposableBag.removeAll()
        let publisher = rtcPeerConnectionCoordinatorFactory.buildCoordinator(
            sessionId: sessionID,
            peerType: .publisher,
            peerConnection: try StreamRTCPeerConnection(
                peerConnectionFactory,
                configuration: connectOptions.rtcConfiguration
            ),
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )

        let subscriber = rtcPeerConnectionCoordinatorFactory.buildCoordinator(
            sessionId: sessionID,
            peerType: .subscriber,
            peerConnection: try StreamRTCPeerConnection(
                peerConnectionFactory,
                configuration: connectOptions.rtcConfiguration
            ),
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )

        publisher
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionPublisher)
            .sinkTask(storeIn: peerConnectionsDisposableBag) { [weak self] in
                await self?.peerConnectionReceivedTrackEvent(.publisher, event: $0)
            }
            .store(in: peerConnectionsDisposableBag)

        subscriber
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionSubscriber)
            .sinkTask(storeIn: peerConnectionsDisposableBag) { [weak self] in
                await self?.peerConnectionReceivedTrackEvent(.subscriber, event: $0)
            }
            .store(in: peerConnectionsDisposableBag)

        try await publisher.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )
        publisher.setVideoFilter(videoFilter)

        try await subscriber.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )

        self.publisher = publisher
        self.subscriber = subscriber
    }

    /// Cleans up the WebRTC session by closing connections and resetting
    /// states.
    func cleanUp() async {
        peerConnectionsDisposableBag.removeAll()
        await publisher?.close()
        await subscriber?.close()
        self.publisher = nil
        self.subscriber = nil
        self.statsReporter = nil
        await sfuAdapter?.disconnect()
        sfuAdapter = nil
        token = ""
        sessionID = ""
        ownCapabilities = []
        participants = [:]
        participantsCount = 0
        anonymousCount = 0
        participantPins = []
        audioTracks = [:]
        videoTracks = [:]
        screenShareTracks = [:]
    }

    /// Cleans up the session for reconnection, clearing adapters and tracks.
    func cleanUpForReconnection() async {
        sfuAdapter = nil
        await publisher?.prepareForClosing()
        await subscriber?.prepareForClosing()
        publisher = nil
        subscriber = nil
        statsReporter = nil
        token = ""
        audioTracks = [:]
        videoTracks = [:]
        screenShareTracks = [:]
        peerConnectionsDisposableBag.removeAll()

        var updatedParticipants = [String: CallParticipant]()
        let participants = self.participants
        for (key, participant) in participants {
            var updatedParticipant = participant
            updatedParticipant.track = nil
            updatedParticipants[key] = participant
        }

        didUpdateParticipants(updatedParticipants)
    }

    /// Restores screen sharing if an active session exists.
    ///
    /// - Throws: Throws an error if the screen sharing session cannot be
    ///   restored.
    func restoreScreenSharing() async throws {
        guard let activeSession = screenShareSessionProvider.activeSession else {
            return
        }
        try await publisher?.beginScreenSharing(
            of: activeSession.screenSharingType,
            ownCapabilities: Array(ownCapabilities)
        )
    }

    // MARK: - Track Management

    /// Adds a track for the given participant ID and track type.
    ///
    /// - Parameters:
    ///   - track: The media stream track to add.
    ///   - type: The type of track (audio, video, screenshare).
    ///   - id: The participant ID associated with the track.
    func didAddTrack(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        for id: String
    ) {
        switch type {
        case .audio:
            if let audioTrack = track as? RTCAudioTrack {
                audioTracks[id] = audioTrack
            }
        case .video:
            if let videoTrack = track as? RTCVideoTrack {
                videoTracks[id] = videoTrack
            }
        case .screenshare:
            if let videoTrack = track as? RTCVideoTrack {
                screenShareTracks[id] = videoTrack
            }
        default:
            break
        }

        guard !participants.isEmpty else { return }

        assignTracksToParticipants(
            participants,
            originalParticipants: self.participants,
            fileName: #file,
            functionName: #function,
            line: #line
        )
    }

    /// Removes a track for the given participant ID.
    ///
    /// - Parameter id: The participant ID whose track should be removed.
    func didRemoveTrack(for id: String, type: TrackType? = nil) {
        if let type {
            switch type {
            case .audio:
                audioTracks[id] = nil
            case .video:
                videoTracks[id] = nil
            case .screenshare:
                screenShareTracks[id] = nil
            default:
                break
            }
        } else {
            audioTracks[id] = nil
            videoTracks[id] = nil
            screenShareTracks[id] = nil
        }

        guard !participants.isEmpty else { return }

        assignTracksToParticipants(
            participants,
            originalParticipants: self.participants,
            fileName: #file,
            functionName: #function,
            line: #line
        )
    }

    /// Retrieves a track by ID and track type.
    ///
    /// - Parameters:
    ///   - id: The participant ID.
    ///   - trackType: The type of track (audio, video, screenshare).
    /// - Returns: The associated media stream track, or `nil` if not found.
    func track(
        for id: String,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        switch trackType {
        case .audio:
            return audioTracks[id]
        case .video:
            return videoTracks[id]
        case .screenshare:
            return screenShareTracks[id]
        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Handles track events when they are added or removed from peer connections.
    private func peerConnectionReceivedTrackEvent(
        _ peerConnectionType: PeerConnectionType,
        event: TrackEvent
    ) {
        switch event {
        case let .added(id, trackType, track):
            didAddTrack(track, type: trackType, for: id)
        case let .removed(id, trackType, _):
            didRemoveTrack(for: id, type: trackType)
        }
    }

    /// Updates the video options and notifies the publisher and subscriber.
    private func didUpdate(videoOptions: VideoOptions) {
        publisher?.videoOptions = videoOptions
        subscriber?.videoOptions = videoOptions
    }

    /// Updates the list of participants and assigns the media tracks to them.
    ///
    /// - Parameters:
    ///   - participants: The new list of participants.
    ///   - fileName: The source file where this update is triggered (for logging).
    ///   - functionName: The function where this update is triggered (for logging).
    ///   - line: The line number where this update is triggered (for logging).
    func didUpdateParticipants(
        _ participants: [String: CallParticipant],
        fileName: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) {
        assignTracksToParticipants(
            participants,
            originalParticipants: self.participants,
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    /// Updates a specific participant's track visibility.
    ///
    /// - Parameters:
    ///   - participant: The participant to update.
    ///   - isVisible: Whether the track should be visible.
    func didUpdateParticipant(
        _ participant: CallParticipant,
        isVisible: Bool
    ) {
        var updatedParticipants = self.participants

        guard
            let _participant = updatedParticipants[participant.id],
            _participant.showTrack != isVisible
        else {
            return
        }

        log.debug("Will toggle visibility for name:\(_participant.name) to isVisible:\(isVisible).")
        updatedParticipants[_participant.id] = _participant
            .withUpdated(showTrack: isVisible)

        didUpdateParticipants(updatedParticipants)
    }

    /// Updates a participant's track size.
    ///
    /// - Parameters:
    ///   - participant: The participant whose track size will be updated.
    ///   - trackSize: The new track size.
    func didUpdateParticipant(
        _ participant: CallParticipant,
        trackSize: CGSize
    ) async {
        var updatedParticipants = self.participants

        guard
            let _participant = participants[participant.id],
            _participant.trackSize != trackSize
        else {
            return
        }

        updatedParticipants[participant.id] = _participant
            .withUpdated(trackSize: trackSize)

        didUpdateParticipants(updatedParticipants)
    }

    /// Assigns media tracks to participants based on track ID and session ID.
    ///
    /// - Parameters:
    ///   - participants: The current list of participants.
    ///   - originalParticipants: The list of participants before the update.
    ///   - fileName: The source file where this function is called (for logging).
    ///   - functionName: The function where this function is called (for logging).
    ///   - line: The line number where this function is called (for logging).
    private func assignTracksToParticipants(
        _ participants: [String: CallParticipant],
        originalParticipants: [String: CallParticipant],
        fileName: StaticString,
        functionName: StaticString,
        line: UInt
    ) {
        log.debug(
            """
            Assigning tracks to participants
            ParticipantsCount: \(participants.count)
            AudioTracksCount: \(audioTracks.count)
            VideoTracksCount: \(videoTracks.count)
            ScreenShareTracksCount: \(screenShareTracks.count)
            """,
            subsystems: .webRTC,
            functionName: functionName,
            fileName: fileName,
            lineNumber: line
        )

        var updatedParticipants: [String: CallParticipant] = [:]
        for (key, participant) in participants {
            var updatedParticipant = participant
            let isLocalUser = updatedParticipant.sessionId == sessionID

            // Assign the correct video track for each participant.
            let videoTrack: RTCVideoTrack? = {
                if
                    let trackLookupPrefix = updatedParticipant.trackLookupPrefix,
                    let videoTrack = videoTracks[trackLookupPrefix],
                    videoTrack.readyState != .ended {
                    return videoTrack
                } else {
                    return videoTracks[key]
                }
            }()

            if
                let videoTrack = videoTrack,
                updatedParticipant.track == nil || updatedParticipant.track?.readyState == .ended {
                updatedParticipant = updatedParticipant.withUpdated(track: videoTrack)
            } else if videoTrack == nil {
                updatedParticipant = updatedParticipant.withUpdated(track: nil)
            }

            // Assign the correct screen sharing track.
            let screenSharingTrack: RTCVideoTrack? = {
                if
                    let trackLookUpPrefix = updatedParticipant.trackLookupPrefix,
                    let screenSharingTrack = screenShareTracks[trackLookUpPrefix] {
                    return screenSharingTrack

                } else if let screenSharingTrack = screenShareTracks[key] {
                    return screenSharingTrack

                } else if
                    isLocalUser,
                    updatedParticipant.isScreensharing,
                    let screenSharingTrack = screenShareTracks[sessionID] {
                    return screenSharingTrack

                } else {
                    return nil
                }
            }()

            if
                let screenSharingTrack,
                updatedParticipant.screenshareTrack == nil || updatedParticipant.screenshareTrack?.readyState == .ended {
                updatedParticipant = updatedParticipant
                    .withUpdated(screensharingTrack: screenSharingTrack)
            } else if screenSharingTrack == nil {
                updatedParticipant = updatedParticipant
                    .withUpdated(screensharingTrack: nil)
            }

            // Toggle track visibility for remote participants.
            if !isLocalUser, let track = updatedParticipant.track {
                if track.isEnabled != updatedParticipant.showTrack {
                    log.debug(
                        "Will toggle track for name:\(participant.name) to isEnabled:\(updatedParticipant.showTrack).",
                        subsystems: .webRTC
                    )
                    updatedParticipant.track?.isEnabled = updatedParticipant.showTrack
                }
            }

            updatedParticipants[key] = updatedParticipant
        }

        let usersWithVideoTracks = updatedParticipants
            .filter { $0.value.track != nil }

        let videoTracksKeys = Set(participants.flatMap { [$0.value.trackLookupPrefix, $0.key].compactMap { $0 } })
        let unusedVideoTracks = videoTracks.filter { !videoTracksKeys.contains($0.key) }

        let usersWithScreenSharingTracks = updatedParticipants
            .filter { $0.value.screenshareTrack != nil }

        guard updatedParticipants != originalParticipants else { return }

        log.debug(
            """
            Participants count: \(updatedParticipants.count)

            Participant TrackKeys:
            \(
                participants.map {
                    """
                    Name: \($0.value.name)
                        Id: \($0.key)
                        LookUpPrefix: \($0.value.trackLookupPrefix ?? "-")
                    """
                }
                .joined(separator: "\n")
            )

            Total tracks:
            AudioTracks: \(audioTracks.count)
            VideoTracks: \(videoTracks.count)
            ScreenShareTracks: \(screenShareTracks.count)

            After assigning tracks to participants the following ones have:
            VideoTracks: \(usersWithVideoTracks.map(\.value.name).joined(separator: ","))
            ScreenShareTracks: \(usersWithScreenSharingTracks.map(\.value.name).joined(separator: ","))

            Muted tracks:
            AudioTracks: \(audioTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))
            VideoTracks: \(videoTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))
            ScreenShareTracks: \(screenShareTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))

            Unused tracks:
            VideoTracks: \(unusedVideoTracks.count) found with keys: \(unusedVideoTracks.map(\.key).joined(separator: ","))
            """,
            subsystems: .webRTC,
            functionName: functionName,
            fileName: fileName,
            lineNumber: line
        )

        self.participants = updatedParticipants
    }
}
