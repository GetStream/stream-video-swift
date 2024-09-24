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
    private var interimParticipants: [String: CallParticipant] = [:]
    private var participantsUpdatesCancellable: AnyCancellable?

    private let rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding
    private let audioSession: AudioSession = .init()
    private let disposableBag = DisposableBag()
    private let peerConnectionsDisposableBag = DisposableBag()

    /// Subject to handle participant updates.
    private lazy var participantsUpdateSubject = PassthroughSubject<[String: CallParticipant], Never>()

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

        Task {
            await set(sessionID: sessionID)
            await configureParticipantsObservation()
        }
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

    private func set(participants: [String: CallParticipant]) {
        self.participants = participants
        log.debug("Participant updated.")
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
                await self?.performParticipantOperation { participants in participants }
            }
            .store(in: peerConnectionsDisposableBag)

        subscriber
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionSubscriber)
            .sinkTask(storeIn: peerConnectionsDisposableBag) { [weak self] in
                await self?.peerConnectionReceivedTrackEvent(.subscriber, event: $0)
                await self?.performParticipantOperation { participants in participants }
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
        interimParticipants = [:]
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

        await performParticipantOperation { participants in
            var updatedParticipants = participants

            for (key, participant) in participants {
                updatedParticipants[key] = participant
                    .withUpdated(track: nil)
                    .withUpdated(screensharingTrack: nil)
            }

            return updatedParticipants
        }
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
    }

    /// Removes a track for the given participant ID.
    ///
    /// - Parameter id: The participant ID whose track should be removed.
    func didRemoveTrack(for id: String) {
        audioTracks[id] = nil
        videoTracks[id] = nil
        screenShareTracks[id] = nil
    }

    /// Retrieves a track by ID and track type.
    ///
    /// - Parameters:
    ///   - id: The participant ID.
    ///   - trackType: The type of track (audio, video, screenshare).
    /// - Returns: The associated media stream track, or `nil` if not found.
    func track(
        for participant: CallParticipant,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        switch trackType {
        case .audio:
            if
                let trackLookupPrefix = participant.trackLookupPrefix,
                let track = audioTracks[trackLookupPrefix]
            {
                return track
            } else {
                return audioTracks[participant.sessionId]
            }

        case .video:
            if
                let trackLookupPrefix = participant.trackLookupPrefix,
                let track = videoTracks[trackLookupPrefix]
            {
                return track
            } else {
                return videoTracks[participant.sessionId]
            }

        case .screenshare:
            if
                let trackLookupPrefix = participant.trackLookupPrefix,
                let track = screenShareTracks[trackLookupPrefix]
            {
                return track
            } else {
                return screenShareTracks[participant.sessionId]
            }

        default:
            return nil
        }
    }

    func performParticipantOperation(
        _ operation: @Sendable @escaping ([String: CallParticipant]) -> [String: CallParticipant],
        fileName: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) async {
        Task {
            let currentParticipants = self.interimParticipants
            var updatedParticipants = operation(currentParticipants)

            if !updatedParticipants.isEmpty {
                updatedParticipants = assignTracksToParticipants(
                    updatedParticipants,
                    fileName: fileName,
                    functionName: functionName,
                    line: line
                )
                self.interimParticipants = updatedParticipants
                self.participantsUpdateSubject.send(updatedParticipants)
            }
        }
    }

    // MARK: - Private Helpers

    private func configureParticipantsObservation() {
        participantsUpdatesCancellable = participantsUpdateSubject
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
            .sinkTask { [weak self] in await self?.set(participants: $0) }
    }

    /// Handles track events when they are added or removed from peer connections.
    private func peerConnectionReceivedTrackEvent(
        _ peerConnectionType: PeerConnectionType,
        event: TrackEvent
    ) {
        switch event {
        case let .added(id, trackType, track):
            didAddTrack(track, type: trackType, for: id)
        case let .removed(id, _, _):
            didRemoveTrack(for: id)
        }
    }

    /// Updates the video options and notifies the publisher and subscriber.
    private func didUpdate(videoOptions: VideoOptions) {
        publisher?.videoOptions = videoOptions
        subscriber?.videoOptions = videoOptions
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
        fileName: StaticString,
        functionName: StaticString,
        line: UInt
    ) -> [String: CallParticipant] {
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

            let videoTrack = track(for: participant, of: .video) as? RTCVideoTrack
            updatedParticipant.track = videoTrack?.readyState != .ended ? videoTrack : nil

            let screenShareTrack = track(for: participant, of: .screenshare) as? RTCVideoTrack
            updatedParticipant.screenshareTrack = screenShareTrack?.readyState != .ended ? screenShareTrack : nil

            updatedParticipants[key] = updatedParticipant
        }

        let remoteParticipants = Array(updatedParticipants.values)
            .filter { $0.sessionId != sessionID && $0.track != nil }
        Task { @MainActor in
            remoteParticipants.forEach { $0.track?.isEnabled = $0.showTrack }
        }

        let usersWithVideoTracks = updatedParticipants
            .compactMap { $0.value.track != nil ? $0.value.name : nil }
            .sorted()
        let usersWithScreenSharingTracks = updatedParticipants
            .compactMap { $0.value.screenshareTrack != nil ? $0.value.name : nil }
            .sorted()
        let usersWithAudioTracksSpeaking = updatedParticipants
            .compactMap { ($0.value.isSpeaking || $0.value.isDominantSpeaker) && track(for: $0.value, of: .audio) != nil ? $0.value.name : nil }
            .sorted()
        log.debug(
            """
            Participants updated from \(participants.count) -> \(updatedParticipants.count). After assigning tracks to participants the following ones have: Speaking: \(usersWithAudioTracksSpeaking.joined(separator: ",")) AudioTracks: \(audioTracks.keys.joined(separator: ",")) Streaming: \(usersWithVideoTracks.joined(separator: ",")) VideoTracks: \(videoTracks.keys.joined(separator: ",")) ScreenSharing: \(usersWithScreenSharingTracks.joined(separator: ","))
            """,
            subsystems: .webRTC,
            functionName: functionName,
            fileName: fileName,
            lineNumber: line
        )

        return updatedParticipants
    }
}
