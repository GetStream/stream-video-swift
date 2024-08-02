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

    private var migratingSFUAdapter: SFUAdapter?
    private var migratingToken: String?

    private(set) var publisher: PeerConnection? {
        didSet {
            log.debug(
                """
                Publisher peerConnection updated with value \(publisher == nil ? "nil" : "non-nil")
                """,
                subsystems: .webRTC
            )
            sfuMiddleware.update(publisher: publisher)
            statsReporter.publisher = publisher
        }
    }

    private(set) var subscriber: PeerConnection? {
        didSet {
            log.debug(
                """
                Subscriber peerConnection updated with value \(publisher == nil ? "nil" : "non-nil")
                """,
                subsystems: .webRTC
            )
            sfuMiddleware.update(subscriber: subscriber)
            statsReporter.subscriber = subscriber
        }
    }

    @Published private(set) var sessionID: String {
        didSet { statsReporter.sessionID = sessionID }
    }

    private var token: String

    private(set) var localVideoTrack: RTCVideoTrack?
    private(set) var localAudioTrack: RTCAudioTrack?
    private(set) var localScreenshareTrack: RTCVideoTrack?
    private(set) var videoCapturer: CameraVideoCapturing?
    private var screenshareCapturer: VideoCapturing?
    private let user: User
    private let callCid: String
    private lazy var audioSession = AudioSession()
    private var connectOptions: ConnectOptions?
    internal var ownCapabilities: [OwnCapability] = []
    private let videoConfig: VideoConfig
    private var audioSettings: AudioSettings?
    private(set) var callSettings = CallSettings()
    private(set) var videoOptions = VideoOptions()
    private let environment: WebSocketClient.Environment
    private let apiKey: String

    private var fromSfuName: String?
    private var tempSubscriber: PeerConnection?
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
            sfuMiddleware.onSessionMigrationEvent = { [weak self] in self?.handleSessionMigrationEvent() }
        }
    }

    // MARK: - v2

    private(set) lazy var statsReporter = WebRTCStatsReporter(sessionID: sessionID)
    private let callAuthenticator: CallAuthenticating
    private var activeMigrationTask: Task<Void, Never>?
    private var activeReconnectionTask: Task<Void, Never>?
    private var sfuReconnectionTime: CGFloat = 30
    weak var delegate: WebRTCClientDelegate?

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
    }

    deinit {
        addOnParticipantsChangeHandlerTask?.cancel()
        state = .init()
    }

    func connect() async throws {
        let response = try await callAuthenticator.authenticate(create: true)

        prepare(
            .connect(
                url: response.credentials.server.url,
                token: response.credentials.token,
                webSocketURL: response.credentials.server.wsEndpoint,
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

        callSettings = response.call.settings.toCallSettings

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
            await setupUserMedia(callSettings: callSettings)
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
            audioSettings: AudioSettings
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
        case let .connect(url, token, webSocketURL, ownCapabilities, audioSettings):
            fromSfuName = nil
            migratingToken = nil
            self.token = token

            self.ownCapabilities = ownCapabilities
            self.audioSettings = audioSettings

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

    func cleanUp() async {
        log.debug("Cleaning up WebRTCClient", subsystems: .webRTC)
        try? await videoCapturer?.stopCapture()
        try? await screenshareCapturer?.stopCapture()
        videoCapturer = nil
        publisher?.close()
        subscriber?.close()
        publisher = nil
        subscriber = nil
        await sfuAdapter.disconnect()
        localAudioTrack?.isEnabled = false
        localAudioTrack = nil
        localVideoTrack?.isEnabled = false
        localVideoTrack = nil
        await state.cleanUp()
        sfuMiddleware.cleanUp()
        onParticipantsUpdated = nil
        onParticipantCountUpdated = nil
        disconnectTime = nil
        activeMigrationTask = nil
    }

    func changeCameraMode(position: CameraPosition) async throws {
        try await setCameraPosition(position == .front ? .front : .back)
    }

    func setupUserMedia(callSettings: CallSettings) async {
        if hasCapability(.sendAudio), localAudioTrack == nil {
            await audioSession.configure(
                audioOn: callSettings.audioOn,
                speakerOn: callSettings.speakerOn
            )

            // Audio
            let audioTrack = await makeAudioTrack()
            localAudioTrack = audioTrack
        }

        if hasCapability(.sendVideo), localVideoTrack == nil {
            // Video
            let videoTrack = await makeVideoTrack()
            localVideoTrack = videoTrack
            await state.add(track: localVideoTrack, id: sessionID)
        }
    }

    func publishUserMedia(callSettings: CallSettings) {
        guard let publisher else {
            log.warning(
                "Trying to publish userMedia but publisher is not available.",
                subsystems: .webRTC
            )
            return
        }

        let canSendAudio = hasCapability(.sendAudio)

        if canSendAudio,
           let audioTrack = localAudioTrack,
           callSettings.audioOn,
           publisher.audioTrackPublished == false {
            let streamIds = ["\(sessionID):audio"]
            log.debug(
                """
                Publishing user audio
                StreamIds: \(streamIds)
                hasCapability: \(canSendAudio)
                isAudioTrackAvailable: \(localAudioTrack != nil)
                isCallSettingsAudioOn: \(callSettings.audioOn),
                isAudioTrackNotPublished: \(publisher.audioTrackPublished == false)
                """,
                subsystems: .webRTC
            )

            publisher.addTrack(
                audioTrack,
                streamIds: streamIds,
                trackType: .audio
            )
        } else {
            log.debug(
                """
                User audio wasn't published
                hasCapability: \(canSendAudio)
                ownCapabilities: \(ownCapabilities.map(\.rawValue))
                isAudioTrackAvailable: \(localAudioTrack != nil)
                isCallSettingsAudioOn: \(callSettings.audioOn),
                isAudioTrackNotPublished: \(publisher.audioTrackPublished == false)
                """,
                subsystems: .webRTC
            )
        }

        let canSendVideo = hasCapability(.sendVideo)

        if hasCapability(.sendVideo),
           callSettings.videoOn,
           let videoTrack = localVideoTrack,
           publisher.videoTrackPublished == false {
            let streamIds = ["\(sessionID):video"]
            log.debug(
                """
                Publishing user video
                StreamIds: \(streamIds)
                hasCapability: \(canSendVideo)
                isVideoTrackAvailable: \(localVideoTrack != nil)
                isCallSettingsVideoOn: \(callSettings.videoOn),
                isVideoTrackNotPublished: \(publisher.videoTrackPublished == false)
                """,
                subsystems: .webRTC
            )

            publisher.addTransceiver(
                videoTrack,
                streamIds: streamIds,
                trackType: .video
            )
        } else {
            log.debug(
                """
                User video wasn't published
                hasCapability: \(canSendVideo)
                ownCapabilities: \(ownCapabilities.map(\.rawValue))
                isVideoTrackAvailable: \(localVideoTrack != nil)
                isCallSettingsVideoOn: \(callSettings.videoOn),
                isVideoTrackNotPublished: \(publisher.videoTrackPublished == false)
                """,
                subsystems: .webRTC
            )
        }
    }

    func changeAudioState(isEnabled: Bool) async throws {
        if isEnabled && (publisher == nil || publisher?.audioTrackPublished == false),
           let configuration = connectOptions?.rtcConfiguration {
            callSettings = CallSettings(
                audioOn: isEnabled,
                videoOn: callSettings.videoOn,
                speakerOn: callSettings.speakerOn,
                audioOutputOn: callSettings.audioOutputOn,
                cameraPosition: callSettings.cameraPosition
            )
            try await publishLocalTracks(configuration: configuration)
        }

        try await sfuAdapter.updateTrackMuteState(
            .audio,
            isMuted: !isEnabled,
            for: sessionID,
            retryPolicy: .neverGonnaGiveYouUp { [weak self] in
                let result = self?.callSettings.audioOn == !isEnabled
                return result
            }
        )
        callSettings = callSettings.withUpdatedAudioState(isEnabled)
        localAudioTrack?.isEnabled = isEnabled
    }

    func changeScreensharingState(isEnabled: Bool) async throws {
        try await sfuAdapter.updateTrackMuteState(
            .screenShare,
            isMuted: !isEnabled,
            for: sessionID
        )
        localScreenshareTrack?.isEnabled = isEnabled
    }

    func changeVideoState(isEnabled: Bool) async throws {
        if isEnabled && (publisher == nil || publisher?.videoTrackPublished == false),
           let configuration = connectOptions?.rtcConfiguration {
            callSettings = CallSettings(
                audioOn: callSettings.audioOn,
                videoOn: isEnabled,
                speakerOn: callSettings.speakerOn,
                audioOutputOn: callSettings.audioOutputOn,
                cameraPosition: callSettings.cameraPosition
            )
            try await publishLocalTracks(configuration: configuration)
        }

        try await sfuAdapter.updateTrackMuteState(
            .video,
            isMuted: !isEnabled,
            for: sessionID,
            retryPolicy: .neverGonnaGiveYouUp { [weak self] in
                self?.callSettings.videoOn == !isEnabled
            }
        )
        callSettings = callSettings.withUpdatedVideoState(isEnabled)
        localVideoTrack?.isEnabled = isEnabled
    }

    func changeSoundState(isEnabled: Bool) async throws {
        await audioSession.setAudioSessionEnabled(isEnabled)
        let audioTracks = await state.audioTracks
        for track in audioTracks.values {
            track.isEnabled = isEnabled
        }
        callSettings = callSettings.withUpdatedAudioOutputState(isEnabled)
    }

    func changeSpeakerState(isEnabled: Bool) async throws {
        await audioSession.configure(audioOn: callSettings.audioOn, speakerOn: isEnabled)
        callSettings = callSettings.withUpdatedSpeakerState(isEnabled)
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
        videoCapturer?.setVideoFilter(videoFilter)
    }

    func startScreensharing(type: ScreensharingType) async throws {
        if hasCapability(.screenshare) {
            if publisher == nil, let configuration = connectOptions?.rtcConfiguration {
                try await publishLocalTracks(configuration: configuration)
            }
            if localScreenshareTrack == nil || type != currentScreenhsareType {
                // Screenshare
                let screenshareTrack = await makeVideoTrack(screenshareType: type)
                localScreenshareTrack = screenshareTrack
                publisher?.addTransceiver(
                    screenshareTrack,
                    streamIds: ["\(sessionID)-screenshare-\(type)"],
                    trackType: .screenshare
                )
                await state.add(screensharingTrack: screenshareTrack, id: sessionID)
                await assignTracksToParticipants()
            } else if localScreenshareTrack?.isEnabled == false {
                localScreenshareTrack?.isEnabled = true
                await state.add(screensharingTrack: localScreenshareTrack, id: sessionID)
                await assignTracksToParticipants()
            }
            try await changeScreensharingState(isEnabled: true)
        } else {
            throw ClientError.MissingPermissions()
        }
        currentScreenhsareType = type
        try await screenshareCapturer?.startCapture(device: nil)
    }

    func stopScreensharing() async throws {
        await state.removeScreensharingTrack(id: sessionID)
        localScreenshareTrack?.isEnabled = false
        await assignTracksToParticipants()
        try await changeScreensharingState(isEnabled: false)
        try? await screenshareCapturer?.stopCapture()
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

    /// Starts noise cancellation for a specified session ID asynchronously.
    /// - Parameters:
    ///   - sessionID: The session ID for which noise cancellation should be started.
    /// - Throws: An error if starting noise cancellation fails.
    func startNoiseCancellation(_ sessionID: String) async throws {
        try await sfuAdapter.toggleNoiseCancellation(true, for: sessionID)
    }

    /// Stops noise cancellation for a specified session ID asynchronously.
    /// - Parameters:
    ///   - sessionID: The session ID for which noise cancellation should be stopped.
    /// - Throws: An error if stopping noise cancellation fails.
    func stopNoiseCancellation(_ sessionID: String) async throws {
        try await sfuAdapter.toggleNoiseCancellation(false, for: sessionID)
    }

    /// Initiates a camera focus operation at the specified point.
    ///
    /// This method attempts to focus the camera at a specific point on the screen.
    /// It requires the `videoCapturer` property to be properly cast to `VideoCapturer` type.
    /// If the casting fails, it throws a `ClientError.Unexpected` error.
    ///
    /// - Parameter point: A `CGPoint` representing the location within the view where the camera
    ///  should focus.
    /// - Throws: A `ClientError.Unexpected` error if `videoCapturer` cannot be cast to
    /// `VideoCapturer`.
    ///
    /// - Note: The `point` parameter should be provided in the coordinate space of the view, where
    /// (0,0) is the top-left corner, and (1,1) is the bottom-right corner. Make sure the camera supports
    /// tap-to-focus functionality before invoking this method.
    func focus(at point: CGPoint) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.focus(at: point)
    }

    /// Adds the `AVCapturePhotoOutput` on the `CameraVideoCapturer` to enable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCapturePhotoOutput` for capturing photos. This enhancement allows applications to capture
    /// still images while video capturing is ongoing.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be added
    /// to the `CameraVideoCapturer`. This output enables the capture of photos alongside video
    /// capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support photo output functionality, an appropriate error
    /// will be thrown to indicate that the operation is not supported.
    ///
    /// - Warning: A maximum of one output of each type may be added.
    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes the `AVCapturePhotoOutput` from the `CameraVideoCapturer` to disable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` by removing an
    /// `AVCapturePhotoOutput` previously added for capturing photos. This action is necessary when
    /// the application needs to stop capturing still images or when adjusting the capturing setup. It ensures
    /// that the video capturing process can continue without the overhead or interference of photo
    /// capturing capabilities.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output disables the capture of photos alongside
    /// video capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support the removal of photo output functionality, an
    /// appropriate error will be thrown to indicate that the operation is not supported.
    ///
    /// - Note: Ensure that the `AVCapturePhotoOutput` being removed was previously added to the
    /// `CameraVideoCapturer`. Attempting to remove an output that is not currently added will not
    /// affect the capture session but may result in unnecessary processing.
    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Adds an `AVCaptureVideoDataOutput` to the `CameraVideoCapturer` for video frame
    /// processing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCaptureVideoDataOutput`, enabling the processing of video frames. This is particularly
    /// useful for applications that require access to raw video data for analysis, filtering, or other processing
    /// tasks while video capturing is in progress.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be added to
    /// the `CameraVideoCapturer`. This output facilitates the capture and processing of live video
    /// frames.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an
    /// `AVCaptureVideoDataOutput`. This functionality is specific to `RTCCameraVideoCapturer`
    /// instances. If the current `CameraVideoCapturer` does not accommodate video output, an error
    /// will be thrown to signify the unsupported operation.
    ///
    /// - Warning: A maximum of one output of each type may be added. For applications linked on or
    /// after iOS 16.0, this restriction no longer applies to AVCaptureVideoDataOutputs. When adding more
    /// than one AVCaptureVideoDataOutput, AVCaptureSession.hardwareCost must be taken into account.
    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.addVideoOutput(videoOutput)
    }

    /// Removes an `AVCaptureVideoDataOutput` from the `CameraVideoCapturer` to disable
    /// video frame processing capabilities.
    ///
    /// This method reconfigures the local user's `CameraVideoCapturer` by removing an
    /// `AVCaptureVideoDataOutput` that was previously added. This change is essential when the
    /// application no longer requires access to raw video data for analysis, filtering, or other processing
    /// tasks, or when adjusting the video capturing setup for different operational requirements. It ensures t
    /// hat video capturing can proceed without the additional processing overhead associated with
    /// handling video frame outputs.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output stops the capture and processing of live video
    /// frames through the specified output, simplifying the capture session.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCaptureVideoDataOutput`. This functionality is tailored for `RTCCameraVideoCapturer`
    /// instances. If the `CameraVideoCapturer` being used does not permit the removal of video outputs,
    /// an error will be thrown to indicate the unsupported operation.
    ///
    /// - Note: It is crucial to ensure that the `AVCaptureVideoDataOutput` intended for removal
    /// has been previously added to the `CameraVideoCapturer`. Trying to remove an output that is
    /// not part of the capture session will have no negative impact but could lead to unnecessary processing
    /// and confusion.
    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.removeVideoOutput(videoOutput)
    }

    /// Zooms the camera video by the specified factor.
    ///
    /// This method attempts to zoom the camera's video feed by adjusting the `videoZoomFactor` of
    /// the camera's active device. It first checks if the video capturer is of type `RTCCameraVideoCapturer`
    /// and if the current camera device supports zoom by verifying that the `videoMaxZoomFactor` of
    /// the active format is greater than 1.0. If these conditions are met, it proceeds to apply the requested
    /// zoom factor, clamping it within the supported range to avoid exceeding the device's capabilities.
    ///
    /// - Parameter factor: The desired zoom factor. A value of 1.0 represents no zoom, while values
    /// greater than 1.0 increase the zoom level. The factor is clamped to the maximum zoom factor supported
    /// by the device to ensure it remains within valid bounds.
    ///
    /// - Throws: `ClientError.Unexpected` if the video capturer is not of type
    /// `RTCCameraVideoCapturer`, or if the device does not support zoom. Also, throws an error if
    /// locking the device for configuration fails.
    ///
    /// - Note: This method should be used cautiously, as setting a zoom factor significantly beyond the
    /// optimal range can degrade video quality.
    func zoom(by factor: CGFloat) throws {
        guard let videoCapturer = videoCapturer as? VideoCapturer else {
            throw ClientError.Unexpected()
        }

        try videoCapturer.zoom(by: factor)
    }

    // MARK: - private

    private func handleOnSocketConnected(reconnected: Bool) {
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

    private func handleOnMigrationJoinResponse(reconnected: Bool) {
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

        subscriber?.onStreamAdded = { [weak self] in self?.handleStreamAdded($0) }
        subscriber?.onStreamRemoved = { [weak self] in self?.handleStreamRemoved($0) }
        subscriber?.onDisconnect = { [weak self] _ in
            log.debug(
                "subscriber disconnected",
                subsystems: .webRTC
            )
            if self?.isFastReconnecting == false {
                log.debug(
                    "notifying of subscriber disconnection",
                    subsystems: .webRTC
                )
                //                self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
                self?.delegate?.webRTCClientDisconnected()
            }
        }

        log.debug("Updating connection status to connected", subsystems: .webRTC)
        await state.update(connectionState: .connected)
        sfuAdapter.sendHealthCheck()
        if callSettings.shouldPublish {
            try await publishLocalTracks(configuration: configuration)
        }
    }

    private func publishLocalTracks(configuration: RTCConfiguration) async throws {
        if publisher == nil {
            publisher = try peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration,
                type: .publisher,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
            publisher?.onDisconnect = { [weak self] _ in
                log.debug(
                    "publisher disconnected",
                    subsystems: .webRTC
                )
                if self?.isFastReconnecting == false {
                    log.debug(
                        "notifying of publisher disconnection",
                        subsystems: .webRTC
                    )
                    //                    self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
                    self?.delegate?.webRTCClientDisconnected()
                }
            }
        } else {
            publisher?.sfuAdapter = sfuAdapter
        }
        await setupUserMedia(callSettings: callSettings)
        publishUserMedia(callSettings: callSettings)
    }

    private func handleStreamAdded(_ stream: RTCMediaStream) {
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
        let trackId = stream.streamId.components(separatedBy: ":").first ?? UUID().uuidString
        Task {
            await state.removeCallParticipant(with: trackId)
        }
    }

    private func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws {
        guard let capturer = videoCapturer else {
            throw ClientError.Unexpected()
        }
        try await capturer.setCameraPosition(cameraPosition)
    }

    private func handleParticipantsUpdated() async {
        await assignTracksToParticipants()
        let state = await self.state.connectionState
        if state == .connected {
            try? await updateParticipantsSubscriptions()
        }
        let participants = await self.state.callParticipants
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
        log.debug("Setting local description for peer connection", subsystems: .webRTC)
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
        if callSettings.videoOn {
            var videoTrack = Stream_Video_Sfu_Models_TrackInfo()
            videoTrack.trackID = localVideoTrack?.trackId ?? ""
            videoTrack.layers = loadLayers(supportedCodecs: videoOptions.supportedCodecs)
            videoTrack.mid = publisher?.transceiver?.mid ?? ""
            videoTrack.trackType = .video
            tracks.append(videoTrack)
        }
        if callSettings.audioOn {
            var audioTrack = Stream_Video_Sfu_Models_TrackInfo()
            audioTrack.trackID = localAudioTrack?.trackId ?? ""
            audioTrack.trackType = .audio
            tracks.append(audioTrack)
        }
        if let localScreenshareTrack, localScreenshareTrack.isEnabled {
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
            if screenshareType == .inApp {
                screenshareCapturer = ScreenshareCapturer(
                    videoSource: videoSource,
                    videoOptions: videoOptions,
                    videoFilters: videoConfig.videoFilters
                )
            } else if screenshareType == .broadcast {
                screenshareCapturer = BroadcastScreenCapturer(
                    videoSource: videoSource,
                    videoOptions: videoOptions,
                    videoFilters: videoConfig.videoFilters
                )
            }
        } else {
            videoCapturer = VideoCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
            let position: AVCaptureDevice.Position = callSettings.cameraPosition == .front ? .front : .back
            let device = videoCapturer?.capturingDevice(for: position)
            try? await videoCapturer?.startCapture(device: device)
        }
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }

    private func makeJoinRequest(
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
            var migration = Stream_Video_Sfu_Event_Migration()
            migration.fromSfuID = fromSfuName ?? sfuAdapter.hostname
            migration.announcedTracks = loadTracks()
            migration.subscriptions = await loadTrackSubscriptionDetails()
            joinRequest.migration = migration
        } else {
            joinRequest.token = token
        }
        return joinRequest
    }

    private func handleSocketConnected(fastReconnect: Bool = false) async throws {
        let sdp: String
        if fastReconnect, let subscriber {
            let offer = try await subscriber.createOffer()
            sdp = offer.sdp
        } else {
            sdp = try await tempOfferSdp()
        }
        await sendJoinRequest(with: sdp, fastReconnect: fastReconnect)
    }

    private func tempOfferSdp() async throws -> String {
        guard let connectOptions = connectOptions else {
            throw ClientError.Unexpected()
        }

        let tempPeerConnection = try peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: connectOptions.rtcConfiguration,
            type: .subscriber,
            sfuAdapter: migratingSFUAdapter ?? sfuAdapter,
            videoOptions: videoOptions
        )

        if let localAudioTrack {
            tempPeerConnection.addTrack(
                localAudioTrack,
                streamIds: ["temp-audio"],
                trackType: .audio
            )
        }

        if let localVideoTrack {
            tempPeerConnection.addTransceiver(
                localVideoTrack,
                streamIds: ["temp-video"],
                direction: .recvOnly,
                trackType: .video
            )
        }
        let offer = try await tempPeerConnection.createOffer()
        tempPeerConnection.transceiver?.stopInternal()
        tempPeerConnection.close()
        return offer.sdp
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
                    screenshareTrack = localScreenshareTrack
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
                log.debug("received participant event", subsystems: .webRTC)
                await self.handleParticipantsUpdated()
            }
        }
    }

    private func hasCapability(_ ownCapability: OwnCapability) -> Bool {
        ownCapabilities.contains(ownCapability)
    }

    private func cleanupMigrationData() {
        migratingSFUAdapter = nil
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
        NotificationCenter
            .default
            .publisher(for: .internetConnectionStatusDidChange)
            .compactMap { $0.userInfo?[Notification.internetConnectionStatusUserInfoKey] as? InternetConnection.Status }
            .log(.debug, subsystems: .webRTC) { "Internet connection state updated to \($0)" }
            .sink { [weak self] in self?.handleConnectionState(isAvailable: $0.isAvailable) }
            .store(in: disposableBag)
    }

    private func handleConnectionState(isAvailable: Bool) {
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
                        callSettings: callSettings,
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
                    create: false
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
                    callSettings: callSettings,
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
                await cleanUp()
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
                    create: false
                )
                let videoOptions = VideoOptions(
                    targetResolution: response.call.settings.video.targetResolution
                )
                let connectOptions = ConnectOptions(
                    iceServers: response.credentials.iceServers
                )

                try await connect(
                    callSettings: callSettings,
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
}

extension WebRTCClient {
    func webSocketClient(
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
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
                if connectionState == .connected {
                    continuation?.yield([true])
                }
            }
        }
        @Published var callParticipants = [String: CallParticipant]() {
            didSet {
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

    func webRTCClientReconnecting()

    func webRTCClientConnected()
}
