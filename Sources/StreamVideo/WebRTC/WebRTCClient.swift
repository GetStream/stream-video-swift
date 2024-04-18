//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@preconcurrency import StreamWebRTC

class WebRTCClient: NSObject, @unchecked Sendable {
    
    enum Constants {
        static let screenshareTrackType = "TRACK_TYPE_SCREEN_SHARE"
        static let videoTrackType = "TRACK_TYPE_VIDEO"
        static let audioTrackType = "TRACK_TYPE_AUDIO"
        static let timeoutInterval: TimeInterval = 15
        static let participantsThreshold = 10
        static let fastReconnectTimeout: TimeInterval = 4.0
    }
    
    actor State: ObservableObject {
        enum Constants {
            static let lowParticipantDelay: UInt64 = 250_000_000
            static let mediumParticipantDelay: UInt64 = 500_000_000
            static let highParticipantDelay: UInt64 = 1_000_000_000
        }
        private var scheduledUpdate = false
        private var cancellables = Set<AnyCancellable>()
        private(set) var lastUpdate: TimeInterval = Date().timeIntervalSince1970
        var connectionState = ConnectionState.disconnected(reason: nil)
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
    
    let state: State
    
    let httpClient: HTTPClient
    var signalService: Stream_Video_Sfu_Signal_SignalServer
    let peerConnectionFactory: PeerConnectionFactory
    
    private(set) var publisher: PeerConnection? {
        didSet {
            sfuMiddleware.update(publisher: publisher)
        }
    }
    
    private(set) var subscriber: PeerConnection? {
        didSet {
            sfuMiddleware.update(subscriber: subscriber)
        }
    }
    
    private(set) var signalChannel: WebSocketClient?
    
    private(set) var sessionID: String
    private var token: String
    
    private(set) var localVideoTrack: RTCVideoTrack?
    private(set) var localAudioTrack: RTCAudioTrack?
    private(set) var localScreenshareTrack: RTCVideoTrack?
    private(set) var videoCapturer: CameraVideoCapturing?
    private var screenshareCapturer: VideoCapturing?
    private let user: User
    private let callCid: String
    private let audioSession = AudioSession()
    private var connectOptions: ConnectOptions?
    internal var ownCapabilities: [OwnCapability]
    private let videoConfig: VideoConfig
    private let audioSettings: AudioSettings
    private(set) var callSettings = CallSettings()
    private(set) var videoOptions = VideoOptions()
    private let environment: WebSocketClient.Environment
    private let apiKey: String
    
    private var migratingSignalService: Stream_Video_Sfu_Signal_SignalServer?
    private var migratingWSClient: WebSocketClient?
    private var migratingToken: String?
    private var fromSfuName: String?
    private var tempSubscriber: PeerConnection?
    private var currentScreenhsareType: ScreensharingType?
    private var isFastReconnecting = false
    private var disconnectTime: Date?
    private lazy var callStatisticsReporter = StreamCallStatisticsReporter()
    
    @Injected(\.thermalStateObserver) private var thermalStateObserver
    
    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    var onSignalConnectionStateChange: ((WebSocketConnectionState) -> Void)?
    var onParticipantCountUpdated: ((UInt32) -> Void)?
    var onSessionMigrationEvent: (() -> Void)? {
        didSet {
            sfuMiddleware.onSessionMigrationEvent = onSessionMigrationEvent
        }
    }
    
    var onSessionMigrationCompleted: (() -> Void)?
    
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
        signalService: signalService,
        subscriber: subscriber,
        publisher: publisher,
        participantThreshold: Constants.participantsThreshold
    )
    
    init(
        user: User,
        apiKey: String,
        hostname: String,
        webSocketURLString: String,
        token: String,
        callCid: String,
        sessionID: String?,
        ownCapabilities: [OwnCapability],
        videoConfig: VideoConfig,
        audioSettings: AudioSettings,
        environment: WebSocketClient.Environment
    ) {
        state = State()
        self.user = user
        self.token = token
        self.callCid = callCid
        self.audioSettings = audioSettings
        self.videoConfig = videoConfig
        self.ownCapabilities = ownCapabilities
        self.sessionID = sessionID ?? UUID().uuidString
        self.environment = environment
        self.apiKey = apiKey
        httpClient = environment.httpClientBuilder()
        
        signalService = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
        peerConnectionFactory = PeerConnectionFactory(
            audioProcessingModule: videoConfig.audioProcessingModule
        )
        super.init()
        if let url = URL(string: webSocketURLString) {
            signalChannel = makeWebSocketClient(url: url, apiKey: .init(apiKey))
        }
        addOnParticipantsChangeHandler()
        subscribeToAppLifecycleChanges()
        subscribeToInternetConnectionUpdates()
    }
    
    func connect(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        migrating: Bool = false,
        fastReconnect: Bool = false
    ) async throws {
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
            signalChannel?.connect()
            sfuMiddleware.onSocketConnected = handleOnSocketConnected
        } else if migrating {
            log.debug("Performing session migration", subsystems: .webRTC)
            migratingWSClient?.connect()
            publisher?.update(configuration: connectOptions.rtcConfiguration)
            sfuMiddleware.onSocketConnected = handleOnMigrationJoinResponse
        } else if fastReconnect {
            log.debug("Performing fast reconnect", subsystems: .webRTC)
            signalChannel?.connect()
            sfuMiddleware.onSocketConnected = handleOnSocketConnected
        }
        sfuMiddleware.onParticipantCountUpdated = { [weak self] participantCount in
            self?.onParticipantCountUpdated?(participantCount)
        }
        sfuMiddleware.onPinsChanged = { [weak self] pins in
            self?.handlePinsChanged(pins)
        }
    }
    
    func prepareForMigration(
        url: String,
        token: String,
        webSocketURL: String,
        fromSfuName: String
    ) {
        self.fromSfuName = fromSfuName
        migratingToken = token
        let signalServer = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: url,
            token: token
        )
        migratingSignalService = signalServer
        if let url = URL(string: webSocketURL) {
            migratingWSClient = makeWebSocketClient(
                url: url,
                apiKey: .init(apiKey),
                isMigrating: true
            )
        }
    }
    
    func cleanUp() async {
        log.debug("Cleaning up WebRTCClient", subsystems: .webRTC)
        try? await videoCapturer?.stopCapture()
        try? await screenshareCapturer?.stopCapture()
        publisher?.close()
        subscriber?.close()
        publisher = nil
        subscriber = nil
        signalChannel?.connectionStateDelegate = nil
        signalChannel?.onWSConnectionEstablished = nil
        signalChannel?.disconnect {}
        signalChannel = nil
        localAudioTrack?.isEnabled = false
        localAudioTrack = nil
        localVideoTrack?.isEnabled = false
        localVideoTrack = nil
        await state.cleanUp()
        sfuMiddleware.cleanUp()
        onParticipantsUpdated = nil
        onSignalConnectionStateChange = nil
        onParticipantCountUpdated = nil
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
        if hasCapability(.sendAudio),
           let audioTrack = localAudioTrack, callSettings.audioOn,
           publisher?.audioTrackPublished == false {
            log.debug("publishing audio track", subsystems: .webRTC)
            publisher?.addTrack(audioTrack, streamIds: ["\(sessionID):audio"], trackType: .audio)
        }
        if hasCapability(.sendVideo),
           callSettings.videoOn,
           let videoTrack = localVideoTrack,
           publisher?.videoTrackPublished == false {
            log.debug("publishing video track", subsystems: .webRTC)
            publisher?.addTransceiver(videoTrack, streamIds: ["\(sessionID):video"], trackType: .video)
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
        var request = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        var audio = Stream_Video_Sfu_Signal_TrackMuteState()
        audio.trackType = .audio
        audio.muted = !isEnabled
        request.muteStates = [audio]
        request.sessionID = sessionID
        let connectURL = signalChannel?.connectURL
        try await executeTask(retryPolicy: .neverGonnaGiveYouUp { [weak self] in
            self?.sfuChanged(connectURL) == false
                && self?.callSettings.audioOn == !isEnabled
        }) {
            _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
            callSettings = callSettings.withUpdatedAudioState(isEnabled)
            localAudioTrack?.isEnabled = isEnabled
        }
    }
    
    func changeScreensharingState(isEnabled: Bool) async throws {
        var request = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        var screenshare = Stream_Video_Sfu_Signal_TrackMuteState()
        screenshare.trackType = .screenShare
        screenshare.muted = !isEnabled
        request.muteStates = [screenshare]
        request.sessionID = sessionID
        try await executeTask(retryPolicy: .fastAndSimple) {
            _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
            localScreenshareTrack?.isEnabled = isEnabled
        }
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
        var request = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        var video = Stream_Video_Sfu_Signal_TrackMuteState()
        video.trackType = .video
        video.muted = !isEnabled
        request.muteStates = [video]
        request.sessionID = sessionID
        let connectURL = signalChannel?.connectURL
        try await executeTask(retryPolicy: .neverGonnaGiveYouUp { [weak self] in
            self?.sfuChanged(connectURL) == false
                && self?.callSettings.videoOn == !isEnabled
        }) {
            _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
            callSettings = callSettings.withUpdatedVideoState(isEnabled)
            localVideoTrack?.isEnabled = isEnabled
        }
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
    
    func collectStats() async throws -> CallStatsReport {
        async let statsPublisher = publisher?.statsReport()
        async let statsSubscriber = subscriber?.statsReport()
        let result = try await [statsPublisher, statsSubscriber]
        return callStatisticsReporter.buildReport(
            publisherReport: .init(result[safe: 0] ?? nil),
            subscriberReport: .init(result[safe: 1] ?? nil),
            datacenter: signalService.hostname
        )
    }
    
    func sendStats(report: CallStatsReport?) async throws {
        guard let report else { return }
        var statsRequest = Stream_Video_Sfu_Signal_SendStatsRequest()
        statsRequest.sessionID = sessionID
        statsRequest.sdk = "stream-ios"
        statsRequest.sdkVersion = SystemEnvironment.version
        statsRequest.webrtcVersion = SystemEnvironment.webRTCVersion
        statsRequest.publisherStats = report.publisherRawStats?.jsonString ?? ""
        statsRequest.subscriberStats = report.subscriberRawStats?.jsonString ?? ""
        _ = try await signalService.sendStats(sendStatsRequest: statsRequest)
    }
    
    func startNoiseCancellation(_ sessionID: String) async throws {
        var request = Stream_Video_Sfu_Signal_StartNoiseCancellationRequest()
        request.sessionID = sessionID
        _ = try await signalService.startNoiseCancellation(startNoiseCancellationRequest: request)
    }

    func stopNoiseCancellation(_ sessionID: String) async throws {
        var request = Stream_Video_Sfu_Signal_StopNoiseCancellationRequest()
        request.sessionID = sessionID
        _ = try await signalService.stopNoiseCancellation(stopNoiseCancellationRequest: request)
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
                    log.debug("reconnected - restarting publisher ice")
                    publisher?.restartIce()
                    await state.update(connectionState: .connected)
                    signalChannel?.engine?.send(message: Stream_Video_Sfu_Event_HealthCheckRequest())
                }
            } catch {
                log.error("Error setting up peer connections", subsystems: .webRTC, error: error)
                await self.state.update(connectionState: .disconnected())
            }
        }
    }
    
    private func handleOnMigrationJoinResponse(reconnected: Bool) {
        signalChannel?.connectionStateDelegate = nil
        signalChannel?.onWSConnectionEstablished = nil
        signalChannel?.disconnect {}
        signalChannel = nil
        signalChannel = migratingWSClient
        if let migratingSignalService {
            signalService = migratingSignalService
            sfuMiddleware.signalService = migratingSignalService
        }
        cleanupMigrationData()
        Task {
            tempSubscriber = subscriber
            tempSubscriber?.paused = true
            try await setupPeerConnections()
            if publisher?.shouldRestartIce == true {
                try await negotiate(peerConnection: publisher, constraints: .iceRestartConstraints)
            }
            subscriber?.onConnected = { [weak self] _ in
                guard let self else { return }
                self.onSessionMigrationCompleted?()
                self.tempSubscriber?.close()
                self.tempSubscriber = nil
                self.subscriber?.onConnected = nil
            }
        }
    }
    
    private func sendMigrationJoinRequest() async {
        do {
            let sdp = try await tempOfferSdp()
            await sendJoinRequest(with: sdp, migrating: true)
        } catch {
            log.error("Error migrating the session")
            cleanupMigrationData()
        }
    }
    
    private func setupPeerConnections() async throws {
        guard let connectOptions = connectOptions else {
            throw ClientError.Unexpected("Connect options not setup")
        }
        log.debug("Creating subscriber peer connection", subsystems: .webRTC)
        let configuration = connectOptions.rtcConfiguration
        subscriber = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: configuration,
            type: .subscriber,
            signalService: signalService,
            videoOptions: videoOptions
        )
        
        subscriber?.onStreamAdded = handleStreamAdded
        subscriber?.onStreamRemoved = handleStreamRemoved
        subscriber?.onDisconnect = { [weak self] _ in
            log.debug("subscriber disconnected")
            if self?.isFastReconnecting == false {
                log.debug("notifying of subscriber disconnection")
                self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
            }
        }
        
        log.debug("Updating connection status to connected", subsystems: .webRTC)
        await state.update(connectionState: .connected)
        signalChannel?.engine?.send(message: Stream_Video_Sfu_Event_HealthCheckRequest())
        if callSettings.shouldPublish {
            try await publishLocalTracks(configuration: configuration)
        }
    }
    
    private func publishLocalTracks(configuration: RTCConfiguration) async throws {
        if publisher == nil {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration,
                type: .publisher,
                signalService: signalService,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
            publisher?.onDisconnect = { [weak self] _ in
                log.debug("publisher disconnected")
                if self?.isFastReconnecting == false {
                    log.debug("notifying of publisher disconnection")
                    self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
                }
            }
        } else {
            publisher?.signalService = signalService
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
                try? await self.negotiate(
                    peerConnection: peerConnection,
                    constraints: constraints
                )
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
        if audioSettings.opusDtxEnabled {
            log.debug("Setting Opus DTX for the audio", subsystems: .webRTC)
            updatedSdp = updatedSdp.replacingOccurrences(
                of: "useinbandfec=1",
                with: "useinbandfec=1;usedtx=1"
            )
        }
        if audioSettings.redundantCodingEnabled {
            updatedSdp = updatedSdp.preferredRedCodec
        }
        let offer = RTCSessionDescription(type: initialOffer.type, sdp: updatedSdp)
        try await peerConnection.setLocalDescription(offer)
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = offer.sdp
        request.sessionID = sessionID
        request.tracks = loadTracks()
        let connectURL = signalChannel?.connectURL
        try await executeTask(retryPolicy: .fastCheckValue { [weak self] in
            self?.sfuChanged(connectURL) == false
        }, task: {
            let response = try await signalService.setPublisher(setPublisherRequest: request)
            let sdp = response.sdp
            log.debug("Setting remote description", subsystems: .webRTC)
            try await peerConnection.setRemoteDescription(sdp, type: .answer)
        })
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
        let audioSource = await peerConnectionFactory.makeAudioSource(audioConstrains)
        let audioTrack = await peerConnectionFactory.makeAudioTrack(source: audioSource)
        return audioTrack
    }
    
    private func makeVideoTrack(screenshareType: ScreensharingType? = nil) async -> RTCVideoTrack {
        let videoSource = await peerConnectionFactory.makeVideoSource(forScreenShare: screenshareType != nil)
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
        let videoTrack = await peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }
    
    private func makeJoinRequest(
        subscriberSdp: String,
        migrating: Bool = false,
        fastReconnect: Bool = false
    ) async -> Stream_Video_Sfu_Event_JoinRequest {
        log.debug("Executing join request", subsystems: .webRTC)
        var joinRequest = Stream_Video_Sfu_Event_JoinRequest()
        joinRequest.clientDetails = SystemEnvironment.clientDetails
        joinRequest.sessionID = sessionID
        joinRequest.subscriberSdp = subscriberSdp
        joinRequest.fastReconnect = fastReconnect
        if migrating {
            joinRequest.token = migratingToken ?? token
            var migration = Stream_Video_Sfu_Event_Migration()
            migration.fromSfuID = fromSfuName ?? signalService.hostname
            migration.announcedTracks = loadTracks()
            migration.subscriptions = await loadTrackSubscriptionDetails()
            joinRequest.migration = migration
        } else {
            joinRequest.token = token
        }
        return joinRequest
    }
    
    private func makeWebSocketClient(
        url: URL,
        apiKey: APIKey,
        isMigrating: Bool = false,
        isFastReconnect: Bool = false
    ) -> WebSocketClient {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        
        // Create a WebSocketClient.
        let webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .sfu,
            environment: environment,
            connectURL: url,
            requiresAuth: false
        )
        
        webSocketClient.connectionStateDelegate = self
        
        webSocketClient.onWSConnectionEstablished = { [weak self] in
            guard let self = self else { return }
            Task {
                if isMigrating {
                    await self.sendMigrationJoinRequest()
                } else {
                    try await self.handleSocketConnected(fastReconnect: isFastReconnect)
                }
            }
        }
        
        return webSocketClient
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
        
        let tempPeerConnection = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: connectOptions.rtcConfiguration,
            type: .subscriber,
            signalService: migratingSignalService ?? signalService,
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
            migratingWSClient?.engine?.send(message: event)
        } else {
            signalChannel?.engine?.send(message: event)
        }
    }
    
    private func updateParticipantsSubscriptions() async throws {
        var request = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        request.sessionID = sessionID
        let tracks = await loadTrackSubscriptionDetails()
        let connectionState = await state.connectionState
        if connectionState == .connected && !tracks.isEmpty {
            request.tracks = tracks
            let lastUpdate = await state.lastUpdate
            try await executeTask(retryPolicy: .neverGonnaGiveYouUp { [weak self] in
                let currentUpdate = await self?.state.lastUpdate
                return currentUpdate == lastUpdate
            }) {
                _ = try await signalService.updateSubscriptions(
                    updateSubscriptionsRequest: request
                )
            }
        }
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
        Task {
            for await _ in await state.callParticipantsUpdates() {
                log.debug("received participant event", subsystems: .webRTC)
                await self.handleParticipantsUpdated()
            }
        }
    }
    
    private func hasCapability(_ ownCapability: OwnCapability) -> Bool {
        ownCapabilities.contains(ownCapability)
    }
    
    private func cleanupMigrationData() {
        migratingWSClient = nil
        migratingSignalService = nil
    }
    
    private func sfuChanged(_ connectURL: URL?) -> Bool {
        signalChannel?.connectURL != connectURL
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionStateChange),
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    @objc private func handleConnectionStateChange(_ notification: NSNotification) {
        guard let status = notification.userInfo?[Notification.internetConnectionStatusUserInfoKey] as? InternetConnection.Status
        else {
            return
        }
        
        handleConnectionState(isAvailable: status.isAvailable)
    }
    
    private func handleConnectionState(isAvailable: Bool) {
        if !isAvailable {
            disconnectTime = Date()
            return
        }
        
        guard isAvailable, !isFastReconnecting else { return }
        
        if let disconnectTime {
            let offlineInterval = Date().timeIntervalSince(disconnectTime)
            log.debug("offline interval is \(offlineInterval) seconds")
            if offlineInterval <= Constants.fastReconnectTimeout {
                isFastReconnecting = true
            }
        }
        
        disconnectTime = nil
        
        if isFastReconnecting, let url = signalChannel?.connectURL {
            signalChannel = makeWebSocketClient(
                url: url,
                apiKey: .init(apiKey),
                isFastReconnect: true
            )
            Task {
                try await connect(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions!,
                    fastReconnect: true
                )
                checkFastReconnectionStatus()
            }
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
                log.debug("Still connecting, check again after the interval")
                self.checkFastReconnectionStatus(retries: 1)
                return
            }
            self.isFastReconnecting = false
            let reconnectPublisher = self.isPeerConnectionDisconnected(self.publisher)
            let reconnectSubscriber = self.isPeerConnectionDisconnected(self.subscriber)
            let shouldFullyReconnect = reconnectPublisher || reconnectSubscriber
            if shouldFullyReconnect {
                log.debug("Fast reconnect failed, doing full reconnect")
                self.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
            } else {
                log.debug("Fast reconnect successfull")
            }
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
}

extension WebRTCClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        log.debug("WS connection state changed to \(state)")
        switch state {
        case .disconnected(source: _), .disconnecting(source: _):
            handleConnectionState(isAvailable: false)
            if !isFastReconnecting && disconnectTime == nil {
                onSignalConnectionStateChange?(state)
            }
        default:
            onSignalConnectionStateChange?(state)
        }
    }
}
