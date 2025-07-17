//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// An actor class that handles WebRTC state management and media tracks for a
/// video call. This class manages the connection setup, track handling, and
/// participants, including their media settings, capabilities, and track
/// updates.
actor WebRTCStateAdapter: ObservableObject, StreamAudioSessionAdapterDelegate {

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
    let unifiedSessionId: String = UUID().uuidString
    let user: User
    let apiKey: String
    let callCid: String
    let videoConfig: VideoConfig
    let peerConnectionFactory: PeerConnectionFactory
    let videoCaptureSessionProvider: VideoCaptureSessionProvider
    let screenShareSessionProvider: ScreenShareSessionProvider
    let audioSession: StreamAudioSession = .init()
    let trackStorage: WebRTCTrackStorage = .init()

    /// Published properties that represent different parts of the WebRTC state.
    @Published private(set) var sessionID: String = UUID().uuidString
    @Published private(set) var token: String = ""
    @Published private(set) var callSettings: CallSettings = .init()
    @Published private(set) var audioSettings: AudioSettings = .init()

    /// Published property to track video options and update them.
    @Published private(set) var videoOptions: VideoOptions = .init() {
        didSet { didUpdate(videoOptions: videoOptions) }
    }

    /// Published property to track publish options and update them.
    @Published private(set) var publishOptions: PublishOptions = .init() {
        didSet { didUpdate(publishOptions: publishOptions) }
    }

    @Published private(set) var connectOptions: ConnectOptions = .init(iceServers: [])
    @Published private(set) var ownCapabilities: Set<OwnCapability> = []
    @Published private(set) var sfuAdapter: SFUAdapter?
    @Published private(set) var publisher: RTCPeerConnectionCoordinator?
    @Published private(set) var subscriber: RTCPeerConnectionCoordinator?
    @Published private(set) var statsCollector: WebRTCStatsCollector?
    @Published private(set) var statsAdapter: WebRTCStatsAdapting?
    @Published private(set) var participants: ParticipantsStorage = [:]
    @Published private(set) var participantsCount: UInt32 = 0
    @Published private(set) var anonymousCount: UInt32 = 0
    @Published private(set) var participantPins: [PinInfo] = []
    @Published private(set) var incomingVideoQualitySettings: IncomingVideoQualitySettings = .none
    @Published private(set) var isTracingEnabled: Bool = false

    private(set) var clientCapabilities: Set<ClientCapability> = [
        .subscriberVideoPause
    ]

    // Various private and internal properties.
    private(set) var initialCallSettings: CallSettings?

    private var videoFilter: VideoFilter?

    private let rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding
    private let disposableBag = DisposableBag()
    private let peerConnectionsDisposableBag = DisposableBag()

    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

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
        
        Task {
            await configureAudioSession()
        }
    }

    deinit {
        audioSession.dismantle()
    }

    /// Sets the session ID.
    func set(sessionID value: String) {
        self.sessionID = value
    }

    /// Sets the call settings.
    func set(
        callSettings value: CallSettings,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        guard value != callSettings else {
            return
        }
        log.debug(
            """
            Updating CallSettings
            From: \(callSettings)
            To: \(value)
            """,
            subsystems: .webRTC,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
        self.callSettings = value
    }

    /// Sets the initial call settings.
    func set(initialCallSettings value: CallSettings?) { self.initialCallSettings = value }

    /// Sets the audio settings.
    func set(audioSettings value: AudioSettings) { self.audioSettings = value }

    /// Sets the video options.
    func set(videoOptions value: VideoOptions) { self.videoOptions = value }

    /// Sets the publish options.
    func set(publishOptions value: PublishOptions) { self.publishOptions = value }

    /// Sets the connection options.
    func set(connectOptions value: ConnectOptions) { self.connectOptions = value }

    /// Sets the own capabilities of the current user.
    func set(ownCapabilities value: Set<OwnCapability>) { self.ownCapabilities = value }

    /// Sets the WebRTC stats reporter.
    func set(statsAdapter value: WebRTCStatsAdapting?) {
        self.statsAdapter = value
        value?.audioSession = audioSession
    }

    /// Sets the SFU (Selective Forwarding Unit) adapter and updates the stats
    /// reporter.
    func set(sfuAdapter value: SFUAdapter?) {
        self.sfuAdapter = value
        statsAdapter?.sfuAdapter = value
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

    func set(isTracingEnabled value: Bool) {
        self.isTracingEnabled = value
        statsAdapter?.isTracingEnabled = value
    }

    // MARK: - Client Capabilities

    func enableClientCapabilities(_ capabilities: Set<ClientCapability>) {
        self.clientCapabilities = self.clientCapabilities.union(capabilities)
    }

    func disableClientCapabilities(_ capabilities: Set<ClientCapability>) {
        self.clientCapabilities = self.clientCapabilities.subtracting(capabilities)
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
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            videoCaptureSessionProvider: videoCaptureSessionProvider,
            screenShareSessionProvider: screenShareSessionProvider,
            clientCapabilities: clientCapabilities
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
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            videoCaptureSessionProvider: videoCaptureSessionProvider,
            screenShareSessionProvider: screenShareSessionProvider,
            clientCapabilities: clientCapabilities
        )

        publisher
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionPublisher)
            .sinkTask(on: self, storeIn: disposableBag, handler: { executor, event in
                await executor.peerConnectionReceivedTrackEvent(.publisher, event: event)
            })
            .store(in: peerConnectionsDisposableBag)

        subscriber
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionSubscriber)
            .sinkTask(on: self, storeIn: disposableBag, handler: { executor, event in
                await executor.peerConnectionReceivedTrackEvent(.subscriber, event: event)
            })
            .store(in: peerConnectionsDisposableBag)

        /// We setUp and restoreScreenSharing on  the publisher in order to prepare all required tracks
        /// for publication. In that way, negotiation will wait until ``completeSetUp`` has been called.
        /// Then, with all the tracks prepared, will continue the negotiation flow.
        try await publisher.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )
        self.publisher = publisher
        try await restoreScreenSharing()
        publisher.setVideoFilter(videoFilter)
        publisher.completeSetUp()

        try await subscriber.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )
        self.subscriber = subscriber
        subscriber.completeSetUp()
    }

    /// Cleans up the WebRTC session by closing connections and resetting
    /// states.
    func cleanUp() async {
        screenShareSessionProvider.activeSession = nil
        videoCaptureSessionProvider.activeSession = nil
        peerConnectionsDisposableBag.removeAll()
        disposableBag.removeAll()
        await publisher?.close()
        await subscriber?.close()
        self.publisher = nil
        self.subscriber = nil
        self.statsAdapter = nil
        await sfuAdapter?.disconnect()
        enqueue { _ in [:] }
        set(sfuAdapter: nil)
        set(token: "")
        set(sessionID: "")
        set(ownCapabilities: [])
        set(participantsCount: 0)
        set(anonymousCount: 0)
        set(participantPins: [])
        trackStorage.removeAll()
    }

    /// Cleans up the session for reconnection, clearing adapters and tracks.
    func cleanUpForReconnection() async {
        set(
            participants: participants
                /// We remove the existing user in order to avoid showing a stale video tile
                /// in the Call.
                .filter { $0.key != sessionID }
                .reduce(into: ParticipantsStorage()) { $0[$1.key] = $1.value.withUpdated(track: nil) }
        )

        peerConnectionsDisposableBag.removeAll()
        disposableBag.removeAll()
        await publisher?.prepareForClosing()
        await subscriber?.prepareForClosing()
        publisher = nil
        subscriber = nil
        set(sfuAdapter: nil)
        set(statsAdapter: nil)
        set(token: "")
        trackStorage.removeAll()

        /// We set the initialCallSettings to the last activated CallSettings, in order to maintain the state
        /// during reconnects.
        initialCallSettings = callSettings
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
        trackStorage.addTrack(track, type: type, for: id)
        enqueue { $0 }
    }

    /// Removes a track for the given participant ID.
    ///
    /// - Parameters:
    ///   - id: The participant ID whose track should be removed.
    ///   - type: The type of track (audio, video, screenshare) or `nil` to remove all.
    func didRemoveTrack(for id: String, type: TrackType? = nil) {
        trackStorage.removeTrack(for: id, type: type)

        enqueue { $0 }
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
            return trackStorage.track(
                for: trackLookupPrefix,
                of: trackType
            ) ?? trackStorage.track(for: participant.sessionId, of: trackType)
        } else {
            return trackStorage.track(for: participant.sessionId, of: trackType)
        }
    }

    /// Retrieves a track by lookup and track type.
    ///
    /// - Parameters:
    ///   - lookup: The participant trackLookUpPrefix or sessionId for which we want to fetch the track.
    ///   - trackType: The type of track (audio, video, screenshare).
    /// - Returns: The associated media stream track, or `nil` if not found.
    func track(
        for lookup: String,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        trackStorage.track(for: lookup, of: trackType)
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
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        processingQueue.addTaskOperation { [weak self] in
            await self?.processEnqueuedOperation(
                operation,
                functionName: functionName,
                fileName: fileName,
                lineNumber: lineNumber
            )
        }
    }

    private func processEnqueuedOperation(
        _ operation: @escaping ParticipantOperation,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
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
            "Participant operation completed. Participants count:\(updated.count).",
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber
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

    func updateCallSettings(
        from event: Stream_Video_Sfu_Event_TrackUnpublished
    ) {
        guard
            event.participant.sessionID == sessionID,
            event.type == .audio || event.type == .video
        else {
            return
        }

        let currentCallSettings = self.callSettings
        let possibleNewCallSettings = {
            switch event.type {
            case .audio:
                return currentCallSettings.withUpdatedAudioState(false)
            case .video:
                return currentCallSettings.withUpdatedVideoState(false)
            default:
                return currentCallSettings
            }
        }()

        guard
            currentCallSettings != possibleNewCallSettings
        else {
            return
        }

        set(callSettings: possibleNewCallSettings)
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

    /// Updates the publish options and notifies the publisher.
    private func didUpdate(publishOptions: PublishOptions) {
        publisher?.publishOptions = publishOptions
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
        if participantsWithVideoTracks.isEmpty {
            log.debug(
                "\(participants.count) participants updated. None of the participants have video.",
                subsystems: .webRTC
            )
        } else {
            log.debug(
                "\(participants.count) participants updated. \(participantsWithVideoTracks) have video tracks.",
                subsystems: .webRTC
            )
        }
    }

    private func configureAudioSession() {
        audioSession.delegate = self

        $callSettings
            .removeDuplicates()
            .sinkTask(storeIn: disposableBag) { [weak audioSession] in
                do {
                    try await audioSession?.didUpdateCallSettings($0)
                } catch {
                    log.error(error)
                }
            }
            .store(in: disposableBag)

        $ownCapabilities
            .removeDuplicates()
            .sinkTask(storeIn: disposableBag) { [weak audioSession] in
                do {
                    try await audioSession?.didUpdateOwnCapabilities($0)
                } catch {
                    log.error(error)
                }
            }
            .store(in: disposableBag)
    }

    // MARK: - AudioSessionDelegate

    nonisolated func audioSessionAdapterDidUpdateCallSettings(
        _ adapter: StreamAudioSession,
        callSettings: CallSettings
    ) {
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
                return
            }
            await self.set(callSettings: callSettings)
            log.debug(
                "AudioSession delegated updated call settings: \(callSettings)",
                subsystems: .audioSession
            )
        }
    }
}
