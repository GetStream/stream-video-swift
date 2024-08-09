//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@preconcurrency import StreamWebRTC

class WebRTCClient: NSObject, @unchecked Sendable {

    private(set) var state: State

    let httpClient: HTTPClient
    let peerConnectionFactory: PeerConnectionFactory

    private(set) var sfuAdapter: SFUAdapter! {
        didSet {
            sfuMiddleware.sfuAdapter = sfuAdapter
            statsReporter.sfuAdapter = sfuAdapter
        }
    }

    private(set) var migratingSFUAdapter: SFUAdapter?
    private var migratingToken: String?

    private var mediaAdapters: [PeerConnectionType: MediaAdapter] = [:]
    private var publisherMediaAdapter: MediaAdapter? { mediaAdapters[.publisher] }
    private var subscriberMediaAdapter: MediaAdapter? { mediaAdapters[.subscriber] }

    private(set) var publisher: PeerConnection? {
        didSet {
            log.debug(
                """
                Publisher peerConnection updated with value \(publisher == nil ? "nil" : "non-nil")
                """,
                subsystems: .webRTC
            )
            if let peerConnection = publisher?.pc {
                makeMediaAdapter(for: .publisher, peerConnection: peerConnection)
                handlePeerConnectionStream(.publisher)
            }
            sfuMiddleware.update(publisher: publisher)
//            statsReporter.publisher = publisher
        }
    }

    private(set) var subscriber: PeerConnection? {
        didSet {
            log.debug(
                """
                Subscriber peerConnection updated with value \(subscriber == nil ? "nil" : "non-nil")
                """,
                subsystems: .webRTC
            )
            if let peerConnection = publisher?.pc {
                makeMediaAdapter(for: .subscriber, peerConnection: peerConnection)
                handlePeerConnectionStream(.subscriber)
            }
            sfuMiddleware.update(subscriber: subscriber)
//            statsReporter.subscriber = subscriber
        }
    }

    @Published private(set) var sessionID: String {
        didSet {
            statsReporter.sessionID = sessionID
        }
    }

    private var previousSessionID: String?
    private var token: String

//    private(set) var localVideoTrack: RTCVideoTrack?
//    private(set) var localAudioTrack: RTCAudioTrack?
//    private(set) var localScreenshareTrack: RTCVideoTrack?
//    private(set) var videoCapturer: CameraVideoCapturing?
//    private var screenshareCapturer: VideoCapturing?
    
    private let user: User
    private let callCid: String
//    private lazy var audioSession = AudioSession()
    private(set) var connectOptions: ConnectOptions?
    internal var ownCapabilities: [OwnCapability] = []
    private let videoConfig: VideoConfig
    private var audioSettings: AudioSettings?
    var callSettings: CallSettings? {
        didSet {
            if let callSettings {
                Task {
                    try await publisherMediaAdapter?.didUpdateCallSettings(callSettings)
                    try await subscriberMediaAdapter?.didUpdateCallSettings(callSettings)
                }
            }
        }
    }
    private(set) var videoOptions = VideoOptions()
    private let environment: WebSocketClient.Environment
    private let apiKey: String

    private var fromSfuName: String?

    private var tempSubscriber: PeerConnection?
    private var tempPublisher: PeerConnection?

    private var currentScreenhsareType: ScreensharingType?
    private var isFastReconnecting = false {
        didSet {
            log.debug(
                "FastReconnecting: \(isFastReconnecting)",
                subsystems: .webRTC
            )
        }
    }

    private var disconnectTime: Date?
    private var addOnParticipantsChangeHandlerTask: Task<Void, Error>?

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    var onParticipantCountUpdated: ((UInt32) -> Void)?
    var disposableBag = DisposableBag()

    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = EventNotificationCenter()
        let middlewares: [EventMiddleware] = [sfuMiddleware]
        center.add(middlewares: middlewares)
        return center
    }()

    private(set) lazy var sfuMiddleware = SfuMiddleware(
        sessionID: sessionID,
        user: user,
        state: state,
        subscriber: subscriber,
        publisher: publisher,
        participantThreshold: Constants.participantsThreshold
    ) {
        didSet {
            guard !useStateMachine else { return }
            sfuMiddleware.onSessionMigrationEvent = { [weak self] in self?.handleSessionMigrationEvent() }
        }
    }

    // MARK: - v2

    private(set) lazy var statsReporter = WebRTCStatsReporter(sessionID: sessionID)
    let callAuthenticator: CallAuthenticating
    private var activeMigrationTask: Task<Void, Never>?
    private var activeReconnectionTask: Task<Void, Never>?
    private var sfuReconnectionTime: CGFloat = 30
    weak var delegate: WebRTCClientDelegate?
    private var stateMachineObserver: AnyCancellable?

    private(set) lazy var stateMachine = StateMachine(
        .init(
            client: self,
            callSettings: callSettings,
            audioSettings: audioSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions,
            fastReconnectDeadlineSeconds: 0
        )
    )

    let useStateMachine = true

    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        environment: WebSocketClient.Environment,
        callAuthenticator: CallAuthenticating
    ) {
        state = State()
        self.user = user
        self.callCid = callCid
        self.videoConfig = videoConfig
        sessionID = UUID().uuidString
        self.environment = environment
        self.apiKey = apiKey
        self.callAuthenticator = callAuthenticator
        httpClient = environment.httpClientBuilder()
        peerConnectionFactory = PeerConnectionFactory(
            audioProcessingModule: videoConfig.audioProcessingModule
        )
        token = ""

        super.init()

        log.debug(
            """
            WebRTC client was created.
            userId: \(user.id)
            callCid: \(callCid)
            sessionID: \(sessionID),
            ownCapabilities: \(ownCapabilities.map(\.rawValue))
            """,
            subsystems: .webRTC
        )

        addOnParticipantsChangeHandler()
        subscribeToAppLifecycleChanges()
        subscribeToInternetConnectionUpdates()

        stateMachineObserver = stateMachine
            .publisher
            .sink { [weak self] in self?.didUpdateStateMachineStage($0) }

        observeForceReconnectionRequests()
    }

    deinit {
        addOnParticipantsChangeHandlerTask?.cancel()
        state = .init()
    }

    func connect(callSettings: CallSettings?) async throws {
        guard useStateMachine == false else {
            self.callSettings = callSettings
            try stateMachine.transition(
                .connecting(
                    .init(
                        client: self,
                        callSettings: callSettings,
                        audioSettings: audioSettings,
                        videoOptions: videoOptions,
                        connectOptions: connectOptions,
                        fastReconnectDeadlineSeconds: 0,
                        reconnectionStrategy: .fast(disconnectedSince: Date.distantFuture, deadline: 0),
                        disconnectionSource: nil
                    )
                )
            )
            return
        }

        let response = try await callAuthenticator.authenticate(
            create: true,
            migratingFrom: nil
        )

        prepare(
            .connect(
                url: response.credentials.server.url,
                token: response.credentials.token,
                webSocketURL: response.credentials.server.wsEndpoint,
                ownCapabilities: response.ownCapabilities,
                audioSettings: response.call.settings.audio,
                connectOptions: ConnectOptions(iceServers: response.credentials.iceServers)
            )
        )

        let videoOptions = VideoOptions(
            targetResolution: response.call.settings.video.targetResolution
        )
        let connectOptions = ConnectOptions(
            iceServers: response.credentials.iceServers
        )

        var callSettings = callSettings ?? response.call.settings.toCallSettings

        try await connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }

    func connect(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        migrating: Bool = false,
        fastReconnect: Bool = false
    ) async throws {
        log.debug(
            """
            Connecting with
            isMigrating: \(migrating)
            isFastReconnecting: \(fastReconnect)
            """,
            subsystems: .webRTC
        )

        let connectionStatus = await state.connectionState
        let isReconnection = migrating || fastReconnect
        if (connectionStatus == .connected || connectionStatus == .connecting) && !isReconnection {
            log.debug("Skipping connection, already connected or connecting", subsystems: .webRTC)
            return
        }
        self.videoOptions = videoOptions
        self.connectOptions = connectOptions
        self.callSettings = callSettings
        log.debug("Connecting to SFU", subsystems: .webRTC)
        await state.update(connectionState: .connecting)
        log.debug("Setting user media", subsystems: .webRTC)
        if !isReconnection {
            isFastReconnecting = false
            try await setupUserMedia(callSettings: callSettings)
            log.debug("Connecting WS channel", subsystems: .webRTC)
            sfuAdapter.connect()
            sfuMiddleware.onSocketConnected = { [weak self] in self?.handleOnSocketConnected(reconnected: $0) }
        } else if migrating {
            log.debug("Performing session migration", subsystems: .webRTC)
            migratingSFUAdapter?.connect()
            publisher?.update(configuration: connectOptions.rtcConfiguration)
            sfuMiddleware.onSocketConnected = handleOnMigrationJoinResponse
        } else if fastReconnect {
            log.debug("Performing fastReconnect", subsystems: .webRTC)
            sfuAdapter.connect()
            sfuMiddleware.onSocketConnected = { [weak self] in self?.handleOnSocketConnected(reconnected: $0) }
        }
        sfuMiddleware.onParticipantCountUpdated = { [weak self] participantCount in
            self?.onParticipantCountUpdated?(participantCount)
        }
        sfuMiddleware.onPinsChanged = { [weak self] pins in
            self?.handlePinsChanged(pins)
        }
    }

    enum PreparationFormat {
        case connect(
            url: String,
            token: String,
            webSocketURL: String,
            ownCapabilities: [OwnCapability],
            audioSettings: AudioSettings,
            connectOptions: ConnectOptions
        )
        case migration(
            url: String,
            token: String,
            webSocketURL: String,
            fromSfuName: String,
            ownCapabilities: [OwnCapability],
            audioSettings: AudioSettings
        )
    }

    func prepare(
        _ format: PreparationFormat
    ) {
        switch format {
        case let .connect(url, token, webSocketURL, ownCapabilities, audioSettings, connectOptions):
            fromSfuName = nil
            migratingToken = nil
            self.token = token

            self.ownCapabilities = ownCapabilities
            self.audioSettings = audioSettings
            self.connectOptions = connectOptions

            sfuAdapter = .init(
                serviceConfiguration: .init(
                    url: .init(string: url)!,
                    apiKey: apiKey,
                    token: token
                ),
                webSocketConfiguration: .init(
                    url: .init(string: webSocketURL)!,
                    eventNotificationCenter: eventNotificationCenter
                )
            )

            sfuAdapter?
                .$connectionState
                .removeDuplicates()
                .sink { [weak self] in self?.webSocketClient(didUpdateConnectionState: $0) }
                .store(in: disposableBag)

            sfuMiddleware.onParticipantCountUpdated = { [weak self] participantCount in
                self?.onParticipantCountUpdated?(participantCount)
            }
            sfuMiddleware.onPinsChanged = { [weak self] pins in
                self?.handlePinsChanged(pins)
            }

        case let .migration(url, token, webSocketURL, fromSfuName, ownCapabilities, audioSettings):
            self.fromSfuName = fromSfuName
            migratingToken = token

            self.ownCapabilities = ownCapabilities
            self.audioSettings = audioSettings

            migratingSFUAdapter = .init(
                serviceConfiguration: .init(
                    url: .init(string: url)!,
                    apiKey: apiKey,
                    token: token
                ),
                webSocketConfiguration: .init(
                    url: .init(string: webSocketURL)!,
                    eventNotificationCenter: eventNotificationCenter
                )
            )

            migratingSFUAdapter?
                .$connectionState
                .removeDuplicates()
                .sink { [weak self] in self?.webSocketClient(didUpdateConnectionState: $0) }
                .store(in: disposableBag)
        }
    }

    func cleanUp() {
        if useStateMachine {
            do {
                try stateMachine.transition(
                    .cleanUp(
                        stateMachine.currentStage.context
                    )
                )
            } catch {
                log.error(error)
            }
        } else {
            Task { [weak self] in await self?._cleanUp() }
        }
    }

    func partialCleanUp() async {
//        try? await videoCapturer?.stopCapture()
//        try? await screenshareCapturer?.stopCapture()
//        localAudioTrack?.isEnabled = false
//        localAudioTrack = nil
//        localVideoTrack?.isEnabled = false
//        localVideoTrack = nil
        await state.partialCleanUp()
    }

    func _cleanUp() async {
        log.debug("Cleaning up WebRTCClient", subsystems: .webRTC)
//        try? await videoCapturer?.stopCapture()
//        try? await screenshareCapturer?.stopCapture()
//        videoCapturer = nil
        publisher?.close()
        subscriber?.close()
        publisher = nil
        subscriber = nil
        if let sfuAdapter {
            await sfuAdapter.disconnect()
        }
//        localAudioTrack?.isEnabled = false
//        localAudioTrack = nil
//        localVideoTrack?.isEnabled = false
//        localVideoTrack = nil
        await state.cleanUp()
        sfuMiddleware.cleanUp()
        onParticipantsUpdated = nil
        onParticipantCountUpdated = nil
        disconnectTime = nil
        activeMigrationTask = nil
//        // TODO: Probably better to do a cleanUp stage here
//        try? stateMachine.transition(
//            .idle(
//                stateMachine.currentStage.context
//            )
//        )
    }

    func changeCameraMode(position: CameraPosition) async throws {
        try await setCameraPosition(position == .front ? .front : .back)
    }

    func setupUserMedia(callSettings: CallSettings) async throws {
        try await publisherMediaAdapter?.setUp(
            with: callSettings,
            ownCapabilities: ownCapabilities
        )
//        if hasCapability(.sendAudio), localAudioTrack == nil {
//            await audioSession.configure(
//                audioOn: callSettings.audioOn,
//                speakerOn: callSettings.speakerOn
//            )
//
//            // Audio
//            let audioTrack = await makeAudioTrack()
//            localAudioTrack = audioTrack
//        }
//
//        if hasCapability(.sendVideo), localVideoTrack == nil {
//            // Video
//            let videoTrack = await makeVideoTrack()
//            localVideoTrack = videoTrack
//            await state.add(track: localVideoTrack, id: sessionID)
//        }
    }

    func publishUserMedia(callSettings: CallSettings) {
//        Task {
//            try await publisherMediaAdapter?.didUpdateCallSettings(callSettings)
//        }

//        guard let publisher else {
//            log.warning(
//                "Trying to publish userMedia but publisher is not available.",
//                subsystems: .webRTC
//            )
//            return
//        }
//
//        let canSendAudio = hasCapability(.sendAudio)
//
//        if canSendAudio,
//           let audioTrack = localAudioTrack,
//           callSettings.audioOn,
//           publisher.audioTrackPublished == false {
//            let streamIds = ["\(sessionID):audio"]
//            log.debug(
//                """
//                Publishing user audio
//                StreamIds: \(streamIds)
//                hasCapability: \(canSendAudio)
//                isAudioTrackAvailable: \(localAudioTrack != nil)
//                isCallSettingsAudioOn: \(callSettings.audioOn),
//                isAudioTrackNotPublished: \(publisher.audioTrackPublished == false)
//                """,
//                subsystems: .webRTC
//            )
//
//            publisher.addTrack(
//                audioTrack,
//                streamIds: streamIds,
//                trackType: .audio
//            )
//        } else {
//            log.debug(
//                """
//                User audio wasn't published
//                hasCapability: \(canSendAudio)
//                ownCapabilities: \(ownCapabilities.map(\.rawValue))
//                isAudioTrackAvailable: \(localAudioTrack != nil)
//                isCallSettingsAudioOn: \(callSettings.audioOn),
//                isAudioTrackNotPublished: \(publisher.audioTrackPublished == false)
//                """,
//                subsystems: .webRTC
//            )
//        }
//
//        let canSendVideo = hasCapability(.sendVideo)
//
//        if hasCapability(.sendVideo),
//           callSettings.videoOn,
//           let videoTrack = localVideoTrack,
//           publisher.videoTrackPublished == false {
//            let streamIds = ["\(sessionID):video"]
//            log.debug(
//                """
//                Publishing user video
//                StreamIds: \(streamIds)
//                hasCapability: \(canSendVideo)
//                isVideoTrackAvailable: \(localVideoTrack != nil)
//                isCallSettingsVideoOn: \(callSettings.videoOn),
//                isVideoTrackNotPublished: \(publisher.videoTrackPublished == false)
//                """,
//                subsystems: .webRTC
//            )
//
//            // TODO: Cache the transceiver when mute/unmute
//            publisher.addTransceiver(
//                videoTrack,
//                streamIds: streamIds,
//                trackType: .video
//            )
//        } else {
//            log.debug(
//                """
//                User video wasn't published
//                hasCapability: \(canSendVideo)
//                ownCapabilities: \(ownCapabilities.map(\.rawValue))
//                isVideoTrackAvailable: \(localVideoTrack != nil)
//                isCallSettingsVideoOn: \(callSettings.videoOn),
//                isVideoTrackNotPublished: \(publisher.videoTrackPublished == false)
//                """,
//                subsystems: .webRTC
//            )
//        }
    }

    func changeAudioState(isEnabled: Bool) async throws {
//        if isEnabled && (publisher == nil || publisher?.audioTrackPublished == false),
//           let configuration = connectOptions?.rtcConfiguration {
//            let callSettings = (callSettings ?? .init())
//                .withUpdatedAudioState(isEnabled)
//            self.callSettings = callSettings
//            try await publishLocalTracks(
//                configuration: configuration,
//                callSettings: callSettings
//            )
//        }
//
//        try await sfuAdapter.updateTrackMuteState(
//            .audio,
//            isMuted: !isEnabled,
//            for: sessionID,
//            retryPolicy: .neverGonnaGiveYouUp { [weak self] in
//                let result = self?.callSettings?.audioOn == !isEnabled
//                return result
//            }
//        )
        callSettings = callSettings?.withUpdatedAudioState(isEnabled)
//        localAudioTrack?.isEnabled = isEnabled
    }

//    func changeScreensharingState(isEnabled: Bool) async throws {
//        try await sfuAdapter.updateTrackMuteState(
//            .screenShare,
//            isMuted: !isEnabled,
//            for: sessionID
//        )
//        localScreenshareTrack?.isEnabled = isEnabled
//    }

    func changeVideoState(isEnabled: Bool) async throws {
//        if isEnabled && (publisher == nil || publisher?.videoTrackPublished == false),
//           let configuration = connectOptions?.rtcConfiguration {
//            let callSettings = (callSettings ?? .init())
//                .withUpdatedVideoState(isEnabled)
//            self.callSettings = callSettings
//            try await publishLocalTracks(
//                configuration: configuration,
//                callSettings: callSettings
//            )
//        }
//
//        try await sfuAdapter.updateTrackMuteState(
//            .video,
//            isMuted: !isEnabled,
//            for: sessionID,
//            retryPolicy: .neverGonnaGiveYouUp { [weak self] in
//                self?.callSettings?.videoOn == !isEnabled
//            }
//        )
        callSettings = callSettings?.withUpdatedVideoState(isEnabled)
//        localVideoTrack?.isEnabled = isEnabled
    }

    func changeSoundState(isEnabled: Bool) async throws {
        await publisherMediaAdapter?.didUpdateAudioSessionState(isEnabled)
//        await audioSession.setAudioSessionEnabled(isEnabled)
//        let audioTracks = await state.audioTracks
//        for track in audioTracks.values {
//            track.isEnabled = isEnabled
//        }
        callSettings = callSettings?.withUpdatedAudioOutputState(isEnabled)
    }

    func changeSpeakerState(isEnabled: Bool) async throws {
        await publisherMediaAdapter?.didUpdateAudioSessionSpeakerState(
            isEnabled,
            with: callSettings?.audioOn ?? false
        )
//        await audioSession.configure(
//            audioOn: callSettings?.audioOn ?? false,
//            speakerOn: isEnabled
//        )
        callSettings = callSettings?.withUpdatedSpeakerState(isEnabled)
    }

    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        guard let participant = await state.callParticipants[participant.id],
              participant.showTrack != isVisible else {
            return
        }
        log.debug("Setting track for \(participant.name) to \(isVisible)", subsystems: .webRTC)
        let trackId = participant.trackLookupPrefix ?? participant.id
        let track = await state.tracks[trackId]
        track?.isEnabled = isVisible
        let updated = participant
            .withUpdated(showTrack: isVisible)
            .withUpdated(track: track)
        await state.update(callParticipant: updated)
        await state.add(track: track, id: trackId)
    }

    func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        guard
            let participant = await state.callParticipants[participant.id],
            participant.trackSize != trackSize
        else {
            return
        }
        let updated = participant.withUpdated(trackSize: trackSize)
        await state.update(callParticipant: updated)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        publisherMediaAdapter?.setVideoFilter(videoFilter)
    }

    func startScreensharing(type: ScreensharingType) async throws {
        try await publisherMediaAdapter?.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
//        if hasCapability(.screenshare) {
//            if 
//                publisher == nil,
//                let configuration = connectOptions?.rtcConfiguration,
//                let callSettings = self.callSettings
//            {
//                try await publishLocalTracks(
//                    configuration: configuration,
//                    callSettings: callSettings
//                )
//            }
//            if localScreenshareTrack == nil || type != currentScreenhsareType {
//                // Screenshare
//                let screenshareTrack = await makeVideoTrack(screenshareType: type)
//                localScreenshareTrack = screenshareTrack
//                publisher?.addTransceiver(
//                    screenshareTrack,
//                    streamIds: ["\(sessionID)-screenshare-\(type)"],
//                    trackType: .screenshare
//                )
//                await state.add(screensharingTrack: screenshareTrack, id: sessionID)
//                await assignTracksToParticipants()
//            } else if localScreenshareTrack?.isEnabled == false {
//                localScreenshareTrack?.isEnabled = true
//                await state.add(screensharingTrack: localScreenshareTrack, id: sessionID)
//                await assignTracksToParticipants()
//            }
//            try await changeScreensharingState(isEnabled: true)
//        } else {
//            throw ClientError.MissingPermissions()
//        }
//        currentScreenhsareType = type
//        try await screenshareCapturer?.startCapture(device: nil)
    }

    func stopScreensharing() async throws {
        publisherMediaAdapter?.stopScreenSharing()
        await state.removeScreensharingTrack(id: sessionID)
        await assignTracksToParticipants()
//        localScreenshareTrack?.isEnabled = false
//        try await changeScreensharingState(isEnabled: false)
//        try? await screenshareCapturer?.stopCapture()
    }

    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        guard let participant = await state.callParticipants[sessionId] else {
            throw ClientError.Unexpected()
        }
        var pin: PinInfo?
        if isEnabled {
            pin = PinInfo(
                isLocal: true,
                pinnedAt: Date()
            )
        }
        let updated = participant.withUpdated(pin: pin)
        await state.update(callParticipant: updated)
    }

    func startNoiseCancellation(_ sessionID: String) async throws {
        try await sfuAdapter.toggleNoiseCancellation(true, for: sessionID)
    }

    func stopNoiseCancellation(_ sessionID: String) async throws {
        try await sfuAdapter.toggleNoiseCancellation(false, for: sessionID)
    }

    func focus(at point: CGPoint) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.focus(at: point)
        try publisherMediaAdapter?.focus(at: point)
    }

    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.addCapturePhotoOutput(capturePhotoOutput)
        try publisherMediaAdapter?.addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.removeCapturePhotoOutput(capturePhotoOutput)
        try publisherMediaAdapter?.removeCapturePhotoOutput(capturePhotoOutput)
    }

    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.addVideoOutput(videoOutput)
        try publisherMediaAdapter?.addVideoOutput(videoOutput)
    }

    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.removeVideoOutput(videoOutput)
        try publisherMediaAdapter?.removeVideoOutput(videoOutput)
    }

    func zoom(by factor: CGFloat) throws {
//        guard let videoCapturer = videoCapturer as? VideoCapturer else {
//            throw ClientError.Unexpected()
//        }
//
//        try videoCapturer.zoom(by: factor)
        try publisherMediaAdapter?.zoom(by: factor)
    }

    // MARK: - private

    private func handleOnSocketConnected(reconnected: Bool) {
        guard !useStateMachine else { return }
        Task {
            do {
                if !reconnected {
                    try await self.setupPeerConnections()
                } else {
                    log.debug("reconnected - restarting publisher ice", subsystems: .webRTC)
                    publisher?.restartIce()
                    sfuAdapter.sendHealthCheck()
                    await state.update(connectionState: .connected)
                }
            } catch {
                log.error("Error setting up peer connections", subsystems: .webRTC, error: error)
                await self.state.update(connectionState: .disconnected())
            }
        }
    }

    func completeMigration() async {
        await sfuAdapter.disconnect()
        sfuAdapter = nil
        sfuAdapter = migratingSFUAdapter
        sfuMiddleware.sfuAdapter = migratingSFUAdapter!
        cleanupMigrationData()

        tempSubscriber = subscriber
        tempSubscriber?.paused = true
    }

    private func handleOnMigrationJoinResponse(reconnected: Bool) {
        guard !useStateMachine else {
            return
        }
        Task {
            await sfuAdapter.disconnect()
            sfuAdapter = nil
            sfuAdapter = migratingSFUAdapter
            sfuMiddleware.sfuAdapter = migratingSFUAdapter!
            cleanupMigrationData()
            do {
                tempSubscriber = subscriber
                tempSubscriber?.paused = true
                try await setupPeerConnections()
                if publisher?.shouldRestartIce == true {
                    try await negotiate(peerConnection: publisher, constraints: .iceRestartConstraints)
                }
                subscriber?.onConnected = { [weak self] _ in
                    guard let self else { return }
                    delegate?.webRTCClientMigrated()
                    self.tempSubscriber?.close()
                    self.tempSubscriber = nil
                    self.subscriber?.onConnected = nil
                }
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
    }

    private func sendMigrationJoinRequest() async {
        do {
            let sdp = try await tempOfferSdp()
            await sendJoinRequest(with: sdp, migrating: true)
        } catch {
            log.error(
                "Error migrating the session",
                subsystems: .webRTC
            )
            cleanupMigrationData()
        }
    }

    private func setupPeerConnections() async throws {
        guard let connectOptions = connectOptions else {
            throw ClientError.Unexpected("Connect options not setup")
        }
        log.debug("Creating subscriber peer connection", subsystems: .webRTC)
        let configuration = connectOptions.rtcConfiguration
        subscriber = try peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: configuration,
            type: .subscriber,
            sfuAdapter: sfuAdapter,
            videoOptions: videoOptions
        )

//        subscriber?.onStreamAdded = { [weak self] in self?.handleStreamAdded($0) }
//        subscriber?.onStreamRemoved = { [weak self] in self?.handleStreamRemoved($0) }
        subscriber?.onDisconnect = { [weak self] _ in
            guard let self else { return }
            log.debug(
                "subscriber disconnected",
                subsystems: .webRTC
            )
            if isFastReconnecting == false {
                log.debug("notifying of subscriber disconnection", subsystems: .webRTC)
                //                self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
                self.delegate?.webRTCClientDisconnected()
                do {
//                    try stateMachine.transition(
//                        .disconnected(
//                            stateMachine.currentStage.context
//                        )
//                    )
                } catch {
                    log.error(error)
                }
            }
        }

        log.debug("Updating connection status to connected", subsystems: .webRTC)
        await state.update(connectionState: .connected)
        sfuAdapter.sendHealthCheck()
        if let callSettings, callSettings.shouldPublish == true {
            try await publishLocalTracks(
                configuration: configuration,
                callSettings: callSettings
            )
        }
    }

    private func publishLocalTracks(
        configuration: RTCConfiguration,
        callSettings: CallSettings
    ) async throws {
        if publisher == nil {
            publisher = try peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration,
                type: .publisher,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions
            )
            publisher?.onConnected = { [weak self] _ in
                self?.tempPublisher?.close()
                self?.tempPublisher = nil
            }

            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
            publisher?.onDisconnect = { [weak self] peerConnection in
                Task { [weak self] in
                    guard let self else { return }
                    do {
//                        peerConnection.restartIce() // That's probably not needed
                        try await self.negotiate(
                            peerConnection: peerConnection,
                            constraints: .iceRestartConstraints
                        )
                    } catch {
                        log.error(error, subsystems: .webRTC)
                        stateMachine.currentStage.context.reconnectionStrategy = .rejoin
                        do {
                            try stateMachine.transition(
                                .disconnected(
                                    stateMachine.currentStage.context
                                )
                            )
                        } catch {
                            log.error(error, subsystems: .webRTC)
                        }
                    }
                }
//                guard let self else { return }
//                log.debug(
//                    "publisher disconnected",
//                    subsystems: .webRTC
//                )
//                if isFastReconnecting == false {
//                    log.debug(
//                        "notifying of publisher disconnection",
//                        subsystems: .webRTC
//                    )
//                    //                    self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
//                    self.delegate?.webRTCClientDisconnected()
//                    do {
////                        try stateMachine.transition(
////                            .disconnected(
////                                stateMachine.currentStage.context
////                            )
////                        )
//                    } catch {
//                        log.error(error)
//                    }
//                }
            }
        } else {
            publisher?.sfuAdapter = sfuAdapter
        }
        try await setupUserMedia(callSettings: callSettings)
        publishUserMedia(callSettings: callSettings)
    }

    private func handleStreamAdded(_ stream: RTCMediaStream) {
        log.debug(
            "Adding stream \(stream.streamId) videoTracks:\(stream.videoTracks.count) audioTrack:\(stream.audioTracks.count).",
            subsystems: .webRTC
        )
        let idParts = stream.streamId.components(separatedBy: ":")
        let trackId = idParts.first ?? UUID().uuidString
        let track = stream.videoTracks.first
        let audioTrack = stream.audioTracks.first
        Task {
            let last = idParts.last
            if last == Constants.videoTrackType && track != nil {
                await self.state.add(track: track, id: trackId)
            } else if last == Constants.screenshareTrackType && track != nil {
                await self.state.add(screensharingTrack: track, id: trackId)
            }
            if audioTrack != nil {
                await self.state.add(audioTrack: audioTrack, id: trackId)
            }
            await assignTracksToParticipants()
        }
    }

    private func handleStreamRemoved(_ stream: RTCMediaStream) {
        log.debug(
            "Removing stream \(stream.streamId) videoTracks:\(stream.videoTracks.count) audioTrack:\(stream.audioTracks.count).",
            subsystems: .webRTC
        )
        let trackId = stream.streamId.components(separatedBy: ":").first ?? UUID().uuidString
        Task {
            await state.removeCallParticipant(with: trackId)
        }
    }

    private func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws {
//        guard let capturer = videoCapturer else {
//            throw ClientError.Unexpected()
//        }
//        try await capturer.setCameraPosition(cameraPosition)
        try await publisherMediaAdapter?.didUpdateCameraPosition(cameraPosition)
    }

    private func handleParticipantsUpdated() async {
        await assignTracksToParticipants()
        let state = await self.state.connectionState
        if state == .connected {
            try? await updateParticipantsSubscriptions()
        }
        let participants = await self.state.callParticipants
//        log.debug(
//            """
//            Will update \(participants.count) participants
//            \(participants.map { "\($0.value.id): \($0.value.trackLookupPrefix ?? "n/a")" })
//            """,
//            subsystems: .webRTC
//        )
        onParticipantsUpdated?(participants)
    }

    private func handleNegotiationNeeded() -> ((PeerConnection, RTCMediaConstraints?) -> Void) {
        { [weak self] peerConnection, constraints in
            guard let self = self else { return }
            Task {
                do {
                    try await self.negotiate(
                        peerConnection: peerConnection,
                        constraints: constraints
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
        }
    }

    private func negotiate(
        peerConnection: PeerConnection?,
        constraints: RTCMediaConstraints? = nil
    ) async throws {
        guard let peerConnection else { return }
        log.debug("Negotiating peer connection", subsystems: .webRTC)

        let initialOffer = try await peerConnection.createOffer(
            constraints: constraints ?? .defaultConstraints
        )
        log.debug("Setting local description for peer connection type:\(peerConnection.type)", subsystems: .webRTC)
        
        var updatedSdp = initialOffer.sdp
        if audioSettings?.opusDtxEnabled == true {
            log.debug("Setting Opus DTX for the audio", subsystems: .webRTC)
            updatedSdp = updatedSdp.replacingOccurrences(
                of: "useinbandfec=1",
                with: "useinbandfec=1;usedtx=1"
            )
        }
        if audioSettings?.redundantCodingEnabled == true {
            updatedSdp = updatedSdp.preferredRedCodec
        }
        let offer = RTCSessionDescription(type: initialOffer.type, sdp: updatedSdp)
        
        try await peerConnection.setLocalDescription(offer)
        
        let response = try await sfuAdapter.setPublisher(
            sessionDescription: offer.sdp,
            tracks: loadTracks(),
            for: sessionID
        )
        let sdp = response.sdp
        log.debug("Setting remote description", subsystems: .webRTC)

        try await peerConnection.setRemoteDescription(sdp, type: .answer)
    }

    private func loadTracks() -> [Stream_Video_Sfu_Models_TrackInfo] {
        var tracks = [Stream_Video_Sfu_Models_TrackInfo]()
        if callSettings?.videoOn == true {
            var videoTrack = Stream_Video_Sfu_Models_TrackInfo()
            videoTrack.trackID = publisherMediaAdapter?.localTrack(of: .video)?.trackId ?? "" //localVideoTrack?.trackId ?? ""
            videoTrack.layers = loadLayers(supportedCodecs: videoOptions.supportedCodecs)
            videoTrack.mid = publisher?.transceiver?.mid ?? ""
            videoTrack.trackType = .video
            tracks.append(videoTrack)
        }
        if callSettings?.audioOn == true {
            var audioTrack = Stream_Video_Sfu_Models_TrackInfo()
            audioTrack.trackID = publisherMediaAdapter?.localTrack(of: .audio)?.trackId ?? "" ///localAudioTrack?.trackId ?? ""
            audioTrack.trackType = .audio
            tracks.append(audioTrack)
        }
        if
            let localScreenshareTrack = publisherMediaAdapter?.localTrack(of: .screenshare),
            localScreenshareTrack.isEnabled
        {
            var screenshareTrack = Stream_Video_Sfu_Models_TrackInfo()
            screenshareTrack.trackID = localScreenshareTrack.trackId
            screenshareTrack.trackType = .screenShare
            screenshareTrack.layers = loadLayers(fps: 15, supportedCodecs: [.screenshare])
            screenshareTrack.mid = publisher?.transceiverScreenshare?.mid ?? ""
            tracks.append(screenshareTrack)
        }
        return tracks
    }

    private func loadLayers(
        fps: UInt32 = 30,
        supportedCodecs: [VideoCodec]
    ) -> [Stream_Video_Sfu_Models_VideoLayer] {
        var layers = [Stream_Video_Sfu_Models_VideoLayer]()
        for codec in supportedCodecs {
            var layer = Stream_Video_Sfu_Models_VideoLayer()
            layer.bitrate = UInt32(codec.maxBitrate)
            layer.rid = codec.quality
            var dimension = Stream_Video_Sfu_Models_VideoDimension()
            dimension.height = UInt32(codec.dimensions.height)
            dimension.width = UInt32(codec.dimensions.width)
            layer.videoDimension = dimension
            layer.fps = fps
            layers.append(layer)
        }

        return layers
    }

    private func makeAudioTrack() async -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory.makeAudioSource(audioConstrains)
        let audioTrack = peerConnectionFactory.makeAudioTrack(source: audioSource)
        return audioTrack
    }

    private func makeVideoTrack(screenshareType: ScreensharingType? = nil) async -> RTCVideoTrack {
        let videoSource = peerConnectionFactory.makeVideoSource(forScreenShare: screenshareType != nil)
        if let screenshareType {
//            if screenshareType == .inApp {
//                screenshareCapturer = ScreenshareCapturer(
//                    videoSource: videoSource,
//                    videoOptions: videoOptions,
//                    videoFilters: videoConfig.videoFilters
//                )
//            } else if screenshareType == .broadcast {
//                screenshareCapturer = BroadcastScreenCapturer(
//                    videoSource: videoSource,
//                    videoOptions: videoOptions,
//                    videoFilters: videoConfig.videoFilters
//                )
//            }
        } else {
//            videoCapturer = VideoCapturer(
//                videoSource: videoSource,
//                videoOptions: videoOptions,
//                videoFilters: videoConfig.videoFilters
//            )
//            let position: AVCaptureDevice.Position = callSettings?.cameraPosition == .front ? .front : .back
//            let device = videoCapturer?.capturingDevice(for: position)
//            try? await videoCapturer?.startCapture(device: device)
        }
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }

    func makeJoinRequest(
        subscriberSdp: String,
        migrating: Bool = false,
        fastReconnect: Bool = false
    ) async -> Stream_Video_Sfu_Event_JoinRequest {
        log.debug("Executing join request with fastReconnect:\(fastReconnect) migrating:\(migrating)", subsystems: .webRTC)
        var joinRequest = Stream_Video_Sfu_Event_JoinRequest()
        joinRequest.clientDetails = SystemEnvironment.clientDetails
        joinRequest.sessionID = sessionID
        joinRequest.subscriberSdp = subscriberSdp
        joinRequest.fastReconnect = fastReconnect
        if migrating {
            joinRequest.token = migratingToken ?? token
            var reconnectDetails = Stream_Video_Sfu_Event_ReconnectDetails()
            reconnectDetails.announcedTracks = loadTracks()
            reconnectDetails.fromSfuID = fromSfuName ?? sfuAdapter.hostname
            reconnectDetails.subscriptions = await loadTrackSubscriptionDetails()
            reconnectDetails.strategy = .migrate
            reconnectDetails.reconnectAttempt = reconnectAttempt
            joinRequest.reconnectDetails = reconnectDetails
        } else if fastReconnect {
            joinRequest.token = token
            var reconnectDetails = Stream_Video_Sfu_Event_ReconnectDetails()
            reconnectDetails.announcedTracks = loadTracks()
            reconnectDetails.fromSfuID = fromSfuName ?? sfuAdapter.hostname
            reconnectDetails.subscriptions = await loadTrackSubscriptionDetails()
            reconnectDetails.strategy = .fast
            reconnectDetails.reconnectAttempt = reconnectAttempt
            joinRequest.reconnectDetails = reconnectDetails
        } else if let previousSessionID {
            joinRequest.token = token
            var reconnectDetails = Stream_Video_Sfu_Event_ReconnectDetails()
            reconnectDetails.announcedTracks = loadTracks()
            reconnectDetails.fromSfuID = fromSfuName ?? sfuAdapter.hostname
            reconnectDetails.subscriptions = await loadTrackSubscriptionDetails()
            reconnectDetails.strategy = .rejoin
            reconnectDetails.previousSessionID = previousSessionID
            reconnectDetails.reconnectAttempt = reconnectAttempt
            joinRequest.reconnectDetails = reconnectDetails
        } else {
            joinRequest.token = token
        }
        reconnectAttempt += 1
        return joinRequest
    }

    private var reconnectAttempt: UInt32 = 0

    private func handleSocketConnected(fastReconnect: Bool = false) async throws {
        guard !useStateMachine else { return }
        let sdp: String
        if fastReconnect, let subscriber {
            let offer = try await subscriber.createOffer()
            sdp = offer.sdp
        } else {
            sdp = try await tempOfferSdp()
        }
        await sendJoinRequest(with: sdp, fastReconnect: fastReconnect)
    }

    func tempOfferSdp() async throws -> String {
        guard let connectOptions = connectOptions else {
            throw ClientError.Unexpected()
        }
        return try await RTCTemporaryPeerConnection(
            sessionID: sessionID,
            peerConnectionFactory: peerConnectionFactory,
            configuration: connectOptions.rtcConfiguration,
            sfuAdapter: sfuAdapter,
            videoOptions: videoOptions,
            localAudioTrack: publisherMediaAdapter?.localTrack(of: .audio) as? RTCAudioTrack, //localAudioTrack,
            localVideoTrack: publisherMediaAdapter?.localTrack(of: .video) as? RTCVideoTrack //localVideoTrack
        ).createOffer().sdp
    }

    private func sendJoinRequest(
        with sdp: String,
        migrating: Bool = false,
        fastReconnect: Bool = false
    ) async {
        let payload = await makeJoinRequest(
            subscriberSdp: sdp,
            migrating: migrating,
            fastReconnect: fastReconnect
        )
        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .joinRequest(payload)
        if migrating {
            migratingSFUAdapter?.send(message: event)
        } else {
            sfuAdapter.send(message: event)
        }
    }

    private func updateParticipantsSubscriptions() async throws {
        let tracks = await loadTrackSubscriptionDetails()
        try await sfuAdapter.updateSubscriptions(tracks: tracks, for: sessionID)
    }

    private func loadTrackSubscriptionDetails() async -> [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        var tracks = [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]()
        let callParticipants = await state.callParticipants

        for (_, value) in callParticipants {
            if value.id != sessionID {
                if value.hasVideo {
                    log.debug(
                        "updating video subscription for user \(value.name) with size \(value.trackSize)",
                        subsystems: .webRTC
                    )
                    var dimension = Stream_Video_Sfu_Models_VideoDimension()
                    dimension.height = UInt32(value.trackSize.height)
                    dimension.width = UInt32(value.trackSize.width)

                    let trackSubscriptionDetails = trackSubscriptionDetails(
                        for: value.userId,
                        sessionId: value.sessionId,
                        dimension: dimension,
                        type: .video
                    )
                    tracks.append(trackSubscriptionDetails)
                }
                if value.hasAudio {
                    let trackSubscriptionDetails = trackSubscriptionDetails(
                        for: value.userId,
                        sessionId: value.sessionId,
                        dimension: Stream_Video_Sfu_Models_VideoDimension(),
                        type: .audio
                    )
                    tracks.append(trackSubscriptionDetails)
                }
                if value.isScreensharing {
                    let trackSubscriptionDetails = trackSubscriptionDetails(
                        for: value.userId,
                        sessionId: value.sessionId,
                        dimension: Stream_Video_Sfu_Models_VideoDimension(),
                        type: .screenShare
                    )
                    tracks.append(trackSubscriptionDetails)
                }
            }
        }
        return tracks
    }

    private func trackSubscriptionDetails(
        for userId: String,
        sessionId: String,
        dimension: Stream_Video_Sfu_Models_VideoDimension,
        type: Stream_Video_Sfu_Models_TrackType
    ) -> Stream_Video_Sfu_Signal_TrackSubscriptionDetails {
        var trackSubscriptionDetails = Stream_Video_Sfu_Signal_TrackSubscriptionDetails()
        trackSubscriptionDetails.userID = userId
        trackSubscriptionDetails.dimension = dimension
        trackSubscriptionDetails.sessionID = sessionId
        trackSubscriptionDetails.trackType = type
        return trackSubscriptionDetails
    }

    private func assignTracksToParticipants() async {
        let callParticipants = await state.callParticipants
        for (_, participant) in callParticipants {
            var track: RTCVideoTrack?
            var screenshareTrack: RTCVideoTrack?
            if let trackId = participant.trackLookupPrefix {
                track = await state.tracks[trackId]
                screenshareTrack = await state.screensharingTracks[trackId]
            }
            if track == nil {
                track = await state.tracks[participant.id]
            }
            if screenshareTrack == nil {
                screenshareTrack = await state.screensharingTracks[participant.id]
            }
            if participant.isScreensharing && screenshareTrack == nil {
                if participant.sessionId == sessionID {
                    screenshareTrack = publisherMediaAdapter?.localTrack(of: .screenshare) as? RTCVideoTrack
                } else {
                    screenshareTrack = subscriber?.findScreensharingTrack(
                        for: participant.trackLookupPrefix
                    )
                }
                if screenshareTrack != nil {
                    await state.add(
                        screensharingTrack: screenshareTrack,
                        id: participant.trackLookupPrefix ?? participant.id
                    )
                }
            }
            var updated: CallParticipant?
            if track != nil && (participant.track == nil || participant.track?.readyState == .ended) {
                updated = participant.withUpdated(track: track)
            }
            if screenshareTrack != nil
                && (participant.screenshareTrack == nil || participant.screenshareTrack?.readyState == .ended) {
                let base = updated ?? participant
                updated = base.withUpdated(screensharingTrack: screenshareTrack)
            }
            if let updated = updated {
                await state.update(callParticipant: updated)
            }
        }
    }

    private func addOnParticipantsChangeHandler() {
        addOnParticipantsChangeHandlerTask = Task { [weak self] in
            guard let self else { return }
            for await _ in await self.state.callParticipantsUpdates() {
//                log.debug("received participant event", subsystems: .webRTC)
                await self.handleParticipantsUpdated()
            }
        }
    }

    private func hasCapability(_ ownCapability: OwnCapability) -> Bool {
        ownCapabilities.contains(ownCapability)
    }

    private func cleanupMigrationData() {
        migratingSFUAdapter = nil
        if let migratingToken {
            token = migratingToken
            self.migratingToken = nil
        }
    }

    @objc private func pauseTracks() {
        Task {
            var pausedTrackIds = [String]()
            let tracks = await state.tracks
            for (id, track) in tracks {
                if id != sessionID {
                    track.isEnabled = false
                    pausedTrackIds.append(id)
                }
            }
            await state.update(pausedTrackIds: pausedTrackIds)
        }
    }

    @objc private func unpauseTracks() {
        Task {
            let tracks = await state.tracks
            let pausedTrackIds = await state.pausedTrackIds
            for (id, track) in tracks {
                if pausedTrackIds.contains(id) {
                    track.isEnabled = true
                }
            }
            await state.update(pausedTrackIds: [])
        }
    }

    private func handlePinsChanged(_ pins: [Stream_Video_Sfu_Models_Pin]) {
        Task {
            let participants = await state.callParticipants
            let sessionIds = pins.map(\.sessionID)
            var updatedParticipants = [String: CallParticipant]()
            for (sessionId, participant) in participants {
                var updated = participant
                if sessionIds.contains(sessionId)
                    && (participant.pin == nil || participant.pin?.isLocal == true) {
                    let pin = PinInfo(
                        isLocal: false,
                        pinnedAt: Date()
                    )
                    updated = participant.withUpdated(pin: pin)
                } else if !sessionIds.contains(sessionId)
                    && (participant.pin != nil && participant.pin?.isLocal == false) {
                    updated = participant.withUpdated(pin: nil)
                }
                updatedParticipants[sessionId] = updated
            }
            await state.update(callParticipants: updatedParticipants)
        }
    }

    private func subscribeToAppLifecycleChanges() {
        let isiOSAppOnMac = {
            if #available(iOS 14.0, *) {
                return ProcessInfo.processInfo.isiOSAppOnMac
            } else {
                return false
            }
        }()

        if !isiOSAppOnMac {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pauseTracks),
                name: UIScene.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(unpauseTracks),
                name: UIScene.willEnterForegroundNotification,
                object: nil
            )
        }
    }

    private func subscribeToInternetConnectionUpdates() {
        guard !useStateMachine else { return }
        NotificationCenter
            .default
            .publisher(for: .internetConnectionStatusDidChange)
            .compactMap { $0.userInfo?[Notification.internetConnectionStatusUserInfoKey] as? InternetConnection.Status }
            .log(.debug, subsystems: .webRTC) { "Internet connection state updated to \($0)" }
            .sink { [weak self] in self?.handleConnectionState(isAvailable: $0.isAvailable) }
            .store(in: disposableBag)
    }

    private func handleConnectionState(isAvailable: Bool) {
        guard !useStateMachine else { return }
        log.debug(
            "Internet connection state changed to isAvailable:\(isAvailable).",
            subsystems: .webRTC
        )
        if !isAvailable {
            disconnectTime = Date()
            log.debug(
                "DisconnectTime was set \(disconnectTime!).",
                subsystems: .webRTC
            )
            return
        }

        log.debug(
            """
            Checking if fastReconnect is possible
            isAvailable:\(isAvailable)
            isFastReconnecting:\(isFastReconnecting)
            hasActiveReconnectionTask:\(activeReconnectionTask != nil)
            """,
            subsystems: .webRTC
        )
        guard
            isAvailable,
            !isFastReconnecting,
            activeReconnectionTask == nil
        else {
            return
        }

        if let disconnectTime {
            let offlineInterval = Date().timeIntervalSince(disconnectTime)
            log.debug(
                """
                We have been offline \(offlineInterval) seconds
                disconnectTime:\(disconnectTime)
                fastReconnectTimeout: \(Constants.fastReconnectTimeout)
                """,
                subsystems: .webRTC
            )
            if offlineInterval <= Constants.fastReconnectTimeout {
                isFastReconnecting = true
            }
        }

        log.debug(
            """
            Final check for fastReconnect
            isFastReconnecting: \(isFastReconnecting)
            disconnectTime:\(disconnectTime)
            """,
            subsystems: .webRTC
        )
        disconnectTime = nil

        if isFastReconnecting {
            log.debug(
                """
                Attempting fastReconnecting
                SFUAdapter hostname: \(sfuAdapter.hostname)
                SFUAdapter connectURL: \(sfuAdapter.connectURL)
                SFUAdapter connectionState: \(sfuAdapter.connectionState)
                """,
                subsystems: .webRTC
            )
            sfuAdapter.refresh(
                webSocketConfiguration: .init(
                    url: sfuAdapter.connectURL,
                    eventNotificationCenter: eventNotificationCenter
                )
            )

            activeReconnectionTask = Task {
                do {
                    try await connect(
                        callSettings: callSettings!,
                        videoOptions: videoOptions,
                        connectOptions: connectOptions!,
                        fastReconnect: true
                    )
                    checkFastReconnectionStatus()
                } catch {
                    log.error(
                        error,
                        subsystems: .webRTC
                    )
                }
            }
        } else {
            log.debug("Cannot attempt fastReconnect.")
        }
    }

    private func checkFastReconnectionStatus(retries: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.fastReconnectTimeout) { [weak self] in
            guard let self else { return }
            if (
                self.isPeerConnectionConnecting(self.publisher, otherNotDisconnected: self.subscriber)
                    || self.isPeerConnectionConnecting(self.subscriber, otherNotDisconnected: self.publisher)
            )
                && retries == 0 {
                log.debug(
                    "Still connecting, check again after the interval",
                    subsystems: .webRTC
                )
                self.checkFastReconnectionStatus(retries: 1)
                return
            }
            let reconnectPublisher = self.isPeerConnectionDisconnected(self.publisher)
            let reconnectSubscriber = self.isPeerConnectionDisconnected(self.subscriber)
            let shouldFullyReconnect = reconnectPublisher || reconnectSubscriber
            if shouldFullyReconnect {
                log.debug(
                    "Fast reconnect failed, doing full reconnect",
                    subsystems: .webRTC
                )
                //                self.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
                self.delegate?.webRTCClientDisconnected()
                do {
                    try stateMachine.transition(
                        .disconnected(
                            stateMachine.currentStage.context
                        )
                    )
                } catch {
                    log.error(error)
                }
            } else {
                log.debug(
                    "Fast reconnect successful.",
                    subsystems: .webRTC
                )
            }

            self.isFastReconnecting = false
        }
    }

    private func isPeerConnectionDisconnected(_ peerConnection: PeerConnection?) -> Bool {
        guard let peerConnection else {
            return false
        }

        switch peerConnection.connectionState {
        case .disconnected, .failed:
            return true
        default:
            return false
        }
    }

    private func isPeerConnectionConnecting(
        _ peerConnection: PeerConnection?,
        otherNotDisconnected other: PeerConnection?
    ) -> Bool {
        let otherState = other?.connectionState
        if peerConnection?.connectionState == .connecting
            && (otherState != .disconnected && otherState != .failed && otherState != .closed) {
            return true
        }
        return false
    }

    private func handleSessionMigrationEvent() {
        guard !useStateMachine else { return }
        guard activeMigrationTask == nil else {
            log.debug(
                "Another migration is in progress.",
                subsystems: .webRTC
            )
            return
        }

        delegate?.webRTCClientMigrating()

        activeMigrationTask = Task {
            do {
                // We don't want to process any events from the old SFU but as we
                // cannot disconnect the ws (as this will cause disconnections on
                // WebRTC connections) we are simply pausing the processing.
                sfuAdapter.updatePaused(true)

                let response = try await callAuthenticator.authenticate(
                    create: false,
                    migratingFrom: sfuAdapter.hostname
                )

                prepare(
                    .migration(
                        url: response.credentials.server.url,
                        token: response.credentials.token,
                        webSocketURL: response.credentials.server.wsEndpoint,
                        fromSfuName: fromSfuName ?? sfuAdapter.hostname,
                        ownCapabilities: response.ownCapabilities,
                        audioSettings: response.call.settings.audio
                    )
                )

                let videoOptions = VideoOptions(
                    targetResolution: response.call.settings.video.targetResolution
                )
                let connectOptions = ConnectOptions(
                    iceServers: response.credentials.iceServers
                )

                try await connect(
                    callSettings: callSettings!,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions,
                    migrating: true
                )
            } catch {
                log.error(
                    error,
                    subsystems: .webRTC
                )
            }

            activeMigrationTask = nil
        }
    }

    private func handleSignalChannelDisconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        isRetry: Bool = false
    ) {
        guard !useStateMachine else { return }
        guard activeReconnectionTask == nil else {
            return
        }
        guard
            (activeReconnectionTask == nil || isRetry),
            source != .userInitiated
        else {
            return
        }

        activeReconnectionTask?.cancel()

        if disconnectTime == nil {
            disconnectTime = Date()
        }

        let diff = Date().timeIntervalSince(disconnectTime ?? Date())

        guard diff <= sfuReconnectionTime else {
            log.debug(
                "Stopping retry mechanism, SFU not available more than 15 seconds",
                subsystems: .webRTC
            )
            delegate?.webRTCClientDisconnected()
            return
        }

        activeReconnectionTask = Task { [weak self] in
            guard let self else { return }
            do {
                // Roll the sessionID
                cleanUp()
                self.sessionID = UUID().uuidString
                log.debug(
                    "Waiting to reconnect",
                    subsystems: .webRTC
                )

                try await Task.sleep(nanoseconds: 250_000_000)

                log.debug(
                    "Retrying to connect to the call",
                    subsystems: .webRTC
                )
                delegate?.webRTCClientReconnecting()
                let response = try await callAuthenticator.authenticate(
                    create: false,
                    migratingFrom: nil
                )
                let videoOptions = VideoOptions(
                    targetResolution: response.call.settings.video.targetResolution
                )
                let connectOptions = ConnectOptions(
                    iceServers: response.credentials.iceServers
                )

                try await connect(
                    callSettings: callSettings!,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )
            } catch {
                if diff > sfuReconnectionTime {
                    delegate?.webRTCClientDisconnected()
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    self.handleSignalChannelDisconnect(source: source, isRetry: true)
                }
            }
        }
    }

    // MARK: - v1.5

    func _setupPeerConnections(
        connectOptions: ConnectOptions,
        videoOptions: VideoOptions
    ) async throws {
        log.debug("Creating subscriber peer connection", subsystems: .webRTC)
        let configuration = connectOptions.rtcConfiguration
        if subscriber == nil {
            subscriber = try peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration,
                type: .subscriber,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions
            )

//            subscriber?.onStreamAdded = { [weak self] in self?.handleStreamAdded($0) }
//            subscriber?.onStreamRemoved = { [weak self] in self?.handleStreamRemoved($0) }
            subscriber?.onDisconnect = { peerConnection in
                peerConnection.restartIce()
                // If that fails, rejoin by observing ice state
            }
        }

        if publisher?.shouldRestartIce == true {
            try await negotiate(
                peerConnection: publisher,
                constraints: .iceRestartConstraints
            )
        }

//        if subscriber?.shouldRestartIce == true {
//            try await negotiate(
//                peerConnection: subscriber,
//                constraints: .iceRestartConstraints
//            )
//        }

        subscriber?.onConnected = { [weak self] _ in
            self?.tempSubscriber?.close()
            self?.tempSubscriber = nil
        }

//        if tempSubscriber != nil {
//            subscriber?.onConnected = { [weak self] _ in
//                guard let self else { return }
//                delegate?.webRTCClientMigrated()
//                self.tempSubscriber?.close()
//                self.tempSubscriber = nil
//                self.subscriber?.onConnected = nil
//            }
//        }
    }

    func _publishLocalTracks(
        connectOptions: ConnectOptions,
        callSettings: CallSettings
    ) async throws {
        do {
        if callSettings.shouldPublish {
            try await publishLocalTracks(
                configuration: connectOptions.rtcConfiguration,
                callSettings: callSettings
            )
        }
            try await publisherMediaAdapter?.didUpdateCallSettings(callSettings)
            try await subscriberMediaAdapter?.didUpdateCallSettings(callSettings)
        } catch {
            log.error(error, subsystems: .webRTC)
        }
    }

    func _closeConnections(of types: [PeerConnectionType]) {
        for peerConnectionType in types {
            switch peerConnectionType {
            case .subscriber:
                subscriber?.close()
                subscriber = nil
            case .publisher:
                publisher?.close()
                publisher = nil
            }
        }
    }

    func leave() {
        if useStateMachine {
            do {
                try stateMachine.transition(
                    .leaving(
                        stateMachine.currentStage.context
                    )
                )
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        } else {
            Task {
                await _cleanUp()
            }
        }
    }

    func updateSession() {
        previousSessionID = sessionID
        sessionID = UUID().uuidString
    }

    private func didUpdateStateMachineStage(
        _ stage: WebRTCClient.StateMachine.Stage
    ) {
        Task { @MainActor in
            switch stage.id {
            case .idle:
                isFastReconnecting = false
                await state.update(connectionState: .disconnected(reason: nil))
            case .rejoining:
                tempPublisher = publisher
                tempSubscriber = subscriber

                subscriber = nil

                await state.update(connectionState: .reconnecting)
            case .fastReconnecting:
                isFastReconnecting = true
                await state.update(connectionState: .reconnecting)
            case .migrating:
                await state.update(connectionState: .reconnecting)
            case .joined:
                isFastReconnecting = false
                previousSessionID = nil
                await state.update(connectionState: .connected)
            case .connecting:
                await state.update(connectionState: .connecting)
            case .disconnected:
                isFastReconnecting = false
                await state.update(connectionState: .disconnected(reason: .networkError(ClientError())))
            default:
                break
            }
        }
    }

    private func observeForceReconnectionRequests() {
        let notificationName = [
            "video",
            "getstream.io",
            "fast",
            "reconnect",
            "request"
        ]

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.fast"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .fast(
                    disconnectedSince: .init(),
                    deadline: stateMachine.currentStage.context.fastReconnectDeadlineSeconds
                )
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.rejoin"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .rejoin
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.migrate"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .migrate
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)
    }

    private func makeMediaAdapter(
        for peerConnectionType: PeerConnectionType,
        peerConnection: RTCPeerConnection
    ) {
        let mediaAdapter = MediaAdapter(
            sessionID: sessionID,
            peerConnectionType: peerConnectionType,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            sfuAdapter: sfuAdapter,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            audioSession: .init()
        )
        mediaAdapters[peerConnectionType] = mediaAdapter
    }

    private func handlePeerConnectionStream(_ peerConnectionType: PeerConnectionType) {
        guard 
            let mediaAdapter = peerConnectionType == .publisher
                ? publisherMediaAdapter
                : subscriberMediaAdapter
        else {
            return
        }

        mediaAdapter
            .trackPublisher
            .receive(on: DispatchQueue.main)
            .compactMap {
                switch $0 {
                case let .added(id, trackType, track):
                    return (id, trackType, track)
                case .removed:
                    return nil
                }
            }
            .sink { [weak self] (event: (id: String, trackType: TrackType, track: RTCMediaStreamTrack)) in
                Task { [weak self] in
                    guard let self else { return }
                    switch event.trackType {
                    case .audio:
                        if let audioTrack = event.track as? RTCAudioTrack {
                            await state.add(audioTrack: audioTrack, id: event.id)
                        }

                    case .video:
                        if let videoTrack = event.track as? RTCVideoTrack {
                            await state.add(track: videoTrack, id: event.id)
                        }

                    case .screenshare:
                        if let videoTrack = event.track as? RTCVideoTrack {
                            await state.add(screensharingTrack: videoTrack, id: event.id)
                        }

                    default:
                        break
                    }

                    await assignTracksToParticipants()
                }
            }
            .store(in: disposableBag)

        mediaAdapter
            .trackPublisher
            .compactMap {
                switch $0 {
                case let .removed(_, _, track):
                    return track.trackId
                case .added:
                    return nil
                }
            }
            .sink { [weak self] (trackId: String) in
                Task { [weak self] in
                    guard let self else { return }
                    await state.removeCallParticipant(with: trackId)
                }
            }
            .store(in: disposableBag)
    }
}

extension WebRTCClient {
    func webSocketClient(
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        guard !useStateMachine else { return }
        log.debug(
            "WS connection state changed to \(state)",
            subsystems: .webRTC
        )
        switch state {
        case let .disconnected(source), let .disconnecting(source):
            log.debug(
                """
                Disconnected from SFU
                connectURL: \(sfuAdapter.connectURL)
                source: \(source)
                isFastReconnecting: \(isFastReconnecting)
                disconnectTime: \(disconnectTime)
                hasActiveReconnectionTask: \(activeReconnectionTask != nil)
                """,
                subsystems: .webRTC
            )
            handleConnectionState(isAvailable: false)
            if !isFastReconnecting, disconnectTime == nil, activeReconnectionTask == nil {
                handleSignalChannelDisconnect(source: source)
            }
        case .authenticating:
            Task {
                do {
                    if migratingSFUAdapter != nil {
                        await self.sendMigrationJoinRequest()
                    } else {
                        try await self.handleSocketConnected(fastReconnect: isFastReconnecting)
                    }
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
        default:
            break
        }
    }
}

extension WebRTCClient {
    enum Constants {
        static let screenshareTrackType = "TRACK_TYPE_SCREEN_SHARE"
        static let videoTrackType = "TRACK_TYPE_VIDEO"
        static let audioTrackType = "TRACK_TYPE_AUDIO"
        static let timeoutInterval: TimeInterval = 15
        static let participantsThreshold = 10
        static let fastReconnectTimeout: TimeInterval = 4.0
    }
}

extension WebRTCClient {
    actor State: ObservableObject {
        enum Constants {
            static let lowParticipantDelay: UInt64 = 250_000_000
            static let mediumParticipantDelay: UInt64 = 500_000_000
            static let highParticipantDelay: UInt64 = 1_000_000_000
        }
        private var scheduledUpdate = false
        private(set) var lastUpdate: TimeInterval = Date().timeIntervalSince1970
        var connectionState = ConnectionState.disconnected(reason: nil) {
            didSet {
                if connectionState == .connected, oldValue != .connected {
                    log.debug(
                        "Connection state updated. Continuation yields.",
                        subsystems: .webRTC
                    )
                    continuation?.yield([true])
                }
            }
        }
        @Published var callParticipants = [String: CallParticipant]() {
            didSet {
//                guard callParticipants != oldValue else { return }
                log.debug(
                    "CallParticipants updated. Continuation yields.",
                    subsystems: .webRTC
                )
                if !scheduledUpdate {
                    scheduledUpdate = true
                    Task {
                        try? await Task.sleep(nanoseconds: participantUpdatesDelay)
                        lastUpdate = Date().timeIntervalSince1970
                        continuation?.yield([true])
                        scheduledUpdate = false
                    }
                }
            }
        }
        var tracks = [String: RTCVideoTrack]()
        var screensharingTracks = [String: RTCVideoTrack]()
        var audioTracks = [String: RTCAudioTrack]()
        var pausedTrackIds = [String]()
        private var continuation: AsyncStream<[Bool]>.Continuation?

        func update(connectionState: ConnectionState) {
            self.connectionState = connectionState
        }

        func update(callParticipants: [String: CallParticipant]) {
            self.callParticipants = callParticipants
        }

        func update(callParticipant: CallParticipant) {
            self.callParticipants[callParticipant.id] = callParticipant
        }

        func removeCallParticipant(with id: String) {
            self.callParticipants.removeValue(forKey: id)
        }

        func add(track: RTCVideoTrack?, id: String) {
            self.tracks[id] = track
        }

        func removeTrack(id: String) {
            self.tracks[id] = nil
        }

        func add(screensharingTrack: RTCVideoTrack?, id: String) {
            self.screensharingTracks[id] = screensharingTrack
        }

        func removeScreensharingTrack(id: String) {
            self.screensharingTracks[id] = nil
        }

        func add(audioTrack: RTCAudioTrack?, id: String) {
            self.audioTracks[id] = audioTrack
        }

        func removeAudioTrack(id: String) {
            self.audioTracks[id] = nil
        }

        func update(tracks: [String: RTCVideoTrack]) {
            self.tracks = tracks
        }

        func update(screensharingTracks: [String: RTCVideoTrack]) {
            self.screensharingTracks = screensharingTracks
        }

        func callParticipantsUpdates() -> AsyncStream<[Bool]> {
            let updates = AsyncStream([Bool].self) { continuation in
                self.continuation = continuation
            }
            return updates
        }

        func update(pausedTrackIds: [String]) {
            self.pausedTrackIds = pausedTrackIds
        }

        func cleanUp() {
            callParticipants = [:]
            tracks = [:]
            audioTracks = [:]
            screensharingTracks = [:]
            connectionState = .disconnected(reason: .user)
            continuation?.finish()
        }

        func partialCleanUp() {
            callParticipants = [:]
            tracks = [:]
            audioTracks = [:]
            screensharingTracks = [:]
        }

        private var participantUpdatesDelay: UInt64 {
            let count = callParticipants.count
            if count < 16 {
                return 0
            } else if count < 50 {
                return Constants.lowParticipantDelay
            } else if count < 100 {
                return Constants.mediumParticipantDelay
            } else {
                return Constants.highParticipantDelay
            }
        }
    }
}

protocol WebRTCClientDelegate: AnyObject {

    func webRTCClientMigrating()
    func webRTCClientMigrated()
    func webRTCClientDisconnected()
    func webRTCClientConnected()
    func webRTCClientReconnecting()
}
