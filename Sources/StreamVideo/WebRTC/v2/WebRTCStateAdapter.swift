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

    typealias ParticipantsStorage = [String: CallParticipant]
    typealias ParticipantOperation = @Sendable(ParticipantsStorage) -> ParticipantsStorage

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
    let videoCaptureSessionProvider: VideoCaptureSessionProvider
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
    @Published private(set) var participants: ParticipantsStorage = [:]
    @Published private(set) var participantsCount: UInt32 = 0
    @Published private(set) var anonymousCount: UInt32 = 0
    @Published private(set) var participantPins: [PinInfo] = []
    @Published private(set) var incomingVideoQualitySettings: IncomingVideoQualitySettings = .none

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
    private var previousParticipantOperation: Task<Void, Never>?

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
    ///   - videoCaptureSessionProvider: Provides sessions for video capturing.
    ///   - screenShareSessionProvider: Provides sessions for screen sharing.
    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding,
        videoCaptureSessionProvider: VideoCaptureSessionProvider = .init(),
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
        self.videoCaptureSessionProvider = videoCaptureSessionProvider
        self.screenShareSessionProvider = screenShareSessionProvider
        let sessionID = UUID().uuidString

        Task {
            await set(sessionID: sessionID)
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

    /// Sets the manual trackSize that will be used when updating subscriptions with the SFU.
    func set(incomingVideoQualitySettings value: IncomingVideoQualitySettings) {
        self.incomingVideoQualitySettings = value
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
            videoCaptureSessionProvider: videoCaptureSessionProvider,
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
            videoCaptureSessionProvider: videoCaptureSessionProvider,
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

        enqueue { participants in
            participants.reduce(into: ParticipantsStorage()) { partialResult, entry in
                partialResult[entry.key] = entry.value.withUpdated(track: nil)
            }
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

        enqueue { $0 }
    }

    /// Removes a track for the given participant ID.
    ///
    /// - Parameters:
    ///   - id: The participant ID whose track should be removed.
    ///   - type: The type of track (audio, video, screenshare) or `nil` to remove all.
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

        enqueue { $0 }
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

    /// Retrieves a track by (trackLookUpPrefix or sessionId) and track type.
    ///
    /// - Parameters:
    ///   - participant: The participant for which we want to fetch the track.
    ///   - trackType: The type of track (audio, video, screenshare).
    /// - Returns: The associated media stream track, or `nil` if not found.
    func track(
        for participant: CallParticipant,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        if let trackLookupPrefix = participant.trackLookupPrefix {
            return track(for: trackLookupPrefix, of: trackType) ?? track(for: participant.sessionId, of: trackType)
        } else {
            return track(for: participant.sessionId, of: trackType)
        }
    }

    // MARK: - Participant Operations

    /// Enqueues a participant operation to be executed asynchronously but in serial order for the actor.
    /// - Parameters:
    ///   - operation: The participant operation to perform.
    ///   - functionName: The name of the calling function. Defaults to the current function name.
    ///   - fileName: The name of the file where the function is called. Defaults to the current file name.
    ///   - lineNumber: The line number where the function is called. Defaults to the current line number.
    func enqueue(
        _ operation: @escaping ParticipantOperation,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        /// Creates a new asynchronous task for the operation.
        let newTask = Task { [previousParticipantOperation] in
            /// Awaits the result of the previous participant operation.
            _ = await previousParticipantOperation?.result

            /// Retrieves the current participants.
            let current = participants
            /// Applies the operation to get the next state of participants.
            let next = operation(current)
            /// Assigns media tracks to the participants.
            let updated = assignTracks(on: next)
            /// Sends the updated participants to observers while helping publishing streamlined updates.
            set(participants: updated)
            /// Logs the completion of the participant operation.
            log.debug(
                "Participant operation completed.",
                functionName: functionName,
                fileName: fileName,
                lineNumber: lineNumber
            )
        }

        /// Stores the new task as the previous operation for chaining.
        previousParticipantOperation = newTask
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

    // MARK: Participant Operations

    /// Updates the current participants and logs those with video tracks.
    /// - Parameter participants: The storage containing participant information.
    private func set(participants: ParticipantsStorage) {
        /// Updates the local participants storage.
        self.participants = participants
        /// Filters participants who have video tracks.
        let participantsWithVideoTracks = participants
            .filter { $0.value.track != nil }
            .map(\.value.name)
            .sorted()
            .joined(separator: ",")
        /// Logs the count and names of participants with video tracks.
        log.debug(
            "\(participants.count) participants updated. \(participantsWithVideoTracks) have video tracks."
        )
    }

    /// Assigns media tracks to participants based on their media type.
    /// - Parameter participants: The storage containing participant information.
    /// - Returns: An updated participants storage with assigned tracks.
    func assignTracks(
        on participants: ParticipantsStorage
    ) -> ParticipantsStorage {
        /// Reduces the participants to a new storage with updated tracks.
        participants.reduce(into: ParticipantsStorage()) { partialResult, entry in
            var newParticipant = entry
                .value
                /// Updates the participant with a video track if available.
                .withUpdated(track: track(for: entry.value, of: .video) as? RTCVideoTrack)
                /// Updates the participant with a screensharing track if available.
                .withUpdated(screensharingTrack: track(for: entry.value, of: .screenshare) as? RTCVideoTrack)

            /// For participants other than the local one, we check if the incomingVideoQualitySettings
            /// provide additional limits.
            if
                newParticipant.sessionId != sessionID,
                incomingVideoQualitySettings.isVideoDisabled(for: entry.value.sessionId)
            {
                newParticipant = newParticipant.withUpdated(track: nil)
            }

            partialResult[entry.key] = newParticipant
        }
    }
}
