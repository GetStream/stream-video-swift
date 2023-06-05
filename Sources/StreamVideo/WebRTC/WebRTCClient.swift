//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@preconcurrency import WebRTC

class WebRTCClient: NSObject {
    
    enum Constants {
        static let screenshareTrackType = "TRACK_TYPE_SCREEN_SHARE"
        static let videoTrackType = "TRACK_TYPE_VIDEO"
        static let audioTrackType = "TRACK_TYPE_AUDIO"
    }
    
    actor State: ObservableObject {
        private var cancellables = Set<AnyCancellable>()
        var connectionState = ConnectionState.disconnected(reason: nil)
        @Published var callParticipants = [String: CallParticipant]() {
            didSet {
                continuation?.yield([true])
            }
        }
        var tracks = [String: RTCVideoTrack]()
        var screensharingTracks = [String: RTCVideoTrack]()
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
        
        func cleanUp() {
            callParticipants = [:]
            tracks = [:]
            screensharingTracks = [:]
            connectionState = .disconnected(reason: .user)
            continuation?.finish()
        }
    }
    
    let state: State
    
    let httpClient: HTTPClient
    let signalService: Stream_Video_Sfu_Signal_SignalServer
    let peerConnectionFactory = PeerConnectionFactory()
    
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
    
    private(set) var sessionID = UUID().uuidString
    private let token: String
    private let timeoutInterval: TimeInterval = 15
    
    private(set) var localVideoTrack: RTCVideoTrack?
    private(set) var localAudioTrack: RTCAudioTrack?
    private var videoCapturer: VideoCapturer?
    private let user: User
    private let callCid: String
    private let audioSession = AudioSession()
    private let participantsThreshold = 10
    private var connectOptions: ConnectOptions?
    private let callCoordinatorController: CallCoordinatorController
    private let videoConfig: VideoConfig
    private let audioSettings: AudioSettings
    private(set) var callSettings = CallSettings()
    private(set) var videoOptions = VideoOptions()
    private let environment: WebSocketClient.Environment
    
    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    var onParticipantEvent: ((ParticipantEvent) -> Void)? {
        didSet {
            sfuMiddleware.onParticipantEvent = onParticipantEvent
        }
    }
    var onSignalConnectionStateChange: ((WebSocketConnectionState) -> ())?
    var onParticipantCountUpdated: ((UInt32) -> ())?
    
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
        participantThreshold: participantsThreshold,
        onParticipantEvent: onParticipantEvent
    )
    
    init(
        user: User,
        apiKey: String,
        hostname: String,
        webSocketURLString: String,
        token: String,
        callCid: String,
        callCoordinatorController: CallCoordinatorController,
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
        self.callCoordinatorController = callCoordinatorController
        self.environment = environment
        httpClient = URLSessionClient(
            urlSession: StreamVideo.Environment.makeURLSession()
        )
        
        signalService = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
        super.init()
        if let url = URL(string: webSocketURLString) {
            signalChannel = makeWebSocketClient(url: url, apiKey: .init(apiKey))
        }
        addOnParticipantsChangeHandler()
    }
    
    func connect(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) async throws {
        let connectionStatus = await state.connectionState
        if connectionStatus == .connected || connectionStatus == .connecting {
            log.debug("Skipping connection, already connected or connecting")
            return
        }
        self.videoOptions = videoOptions
        self.connectOptions = connectOptions
        self.callSettings = callSettings
        log.debug("Connecting to SFU")
        await state.update(connectionState: .connecting)
        log.debug("Setting user media")
        await setupUserMedia(callSettings: callSettings)
        log.debug("Connecting WS channel")
        signalChannel?.connect()
        sfuMiddleware.onSocketConnected = handleOnSocketConnected
    }
    
    func cleanUp() async {
        videoCapturer?.stopCameraCapture()
        videoCapturer = nil
        publisher = nil
        subscriber = nil
        signalChannel?.onWSConnectionEstablished = nil
        signalChannel?.participantCountUpdated = nil
        signalChannel?.disconnect {}
        signalChannel = nil
        localAudioTrack = nil
        localVideoTrack = nil
        sessionID = UUID().uuidString
        await state.cleanUp()
        sfuMiddleware.cleanUp()
        onParticipantsUpdated = nil
        onParticipantEvent = nil
        onSignalConnectionStateChange = nil
        onParticipantCountUpdated = nil
    }
    
    func startCapturingLocalVideo(cameraPosition: AVCaptureDevice.Position) {
        setCameraPosition(cameraPosition) {
            log.debug("Started capturing local video")
        }
    }
    
    func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        setCameraPosition(position == .front ? .front : .back, completion: completion)
    }
    
    func setupUserMedia(callSettings: CallSettings) async {
        if hasCapability(.sendAudio) {
            await audioSession.configure(callSettings: callSettings)
            
            // Audio
            let audioTrack = await makeAudioTrack()
            localAudioTrack = audioTrack
        }
        
        if hasCapability(.sendVideo) {
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
            log.debug("publishing audio track")
            publisher?.addTrack(audioTrack, streamIds: ["\(sessionID):audio"], trackType: .audio)
        }
        if hasCapability(.sendVideo),
            callSettings.videoOn,
            let videoTrack = localVideoTrack,           
            publisher?.videoTrackPublished == false {
            log.debug("publishing video track")
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
        _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
        localAudioTrack?.isEnabled = isEnabled
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
        _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
        localVideoTrack?.isEnabled = isEnabled
    }
    
    func changeSoundState(isEnabled: Bool) async throws {
        await audioSession.setAudioSessionEnabled(isEnabled)
    }
    
    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        guard let participant = await state.callParticipants[participant.id],
              participant.showTrack != isVisible else {
            return
        }
        log.debug("Setting track for \(participant.name) to \(isVisible)")
        let updated = participant.withUpdated(showTrack: isVisible)
        let trackId = participant.trackLookupPrefix ?? participant.id
        let track = await state.tracks[trackId]
        track?.isEnabled = isVisible
        await state.update(callParticipant: updated)
        await state.add(track: track, id: trackId)
    }
    
    func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        guard let participant = await state.callParticipants[participant.id] else {
            return
        }
        let updated = participant.withUpdated(trackSize: trackSize)
        await state.update(callParticipant: updated)
    }
    
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoCapturer?.setVideoFilter(videoFilter)
    }
    
    // MARK: - private
    
    private func handleOnSocketConnected() {
        Task {
            do {
                try await self.setupPeerConnections()
            } catch {
                log.error("Error setting up peer connections")
                await self.state.update(connectionState: .disconnected())
            }
        }
    }
    
    private func setupPeerConnections() async throws {
        guard let connectOptions = connectOptions else {
            throw ClientError.Unexpected("Connect options not setup")
        }
        log.debug("Creating subscriber peer connection")
        let configuration = connectOptions.rtcConfiguration
        subscriber = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            callCid: callCid,
            configuration: configuration,
            type: .subscriber,
            coordinatorClient: callCoordinatorController.coordinatorClient,
            signalService: signalService,
            videoOptions: videoOptions
        )
        
        subscriber?.onStreamAdded = handleStreamAdded
        subscriber?.onStreamRemoved = handleStreamRemoved
        
        log.debug("Updating connection status to connected")
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
                callCid: callCid,
                configuration: configuration,
                type: .publisher,
                coordinatorClient: callCoordinatorController.coordinatorClient,
                signalService: signalService,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
            publisher?.onDisconnect = { [weak self] _ in
                self?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
            }
        }
        publishUserMedia(callSettings: callSettings)
    }
    
    private func handleStreamAdded(_ stream: RTCMediaStream) {
        let idParts = stream.streamId.components(separatedBy: ":")
        let trackId = idParts.first ?? UUID().uuidString
        let track = stream.videoTracks.first
        Task {
            let last = idParts.last
            if last == Constants.videoTrackType && track != nil {
                await self.state.add(track: track, id: trackId)
            } else if last == Constants.screenshareTrackType && track != nil {
                await self.state.add(screensharingTrack: track, id: trackId)
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
    
    private func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position, completion: @escaping () -> ()) {
        guard let capturer = videoCapturer else { return }
        capturer.setCameraPosition(cameraPosition, completion: completion)
    }
    
    private func handleParticipantsUpdated() async {
        await assignTracksToParticipants()
        let state = await self.state.connectionState
        if state == .connected {
            await updateParticipantsSubscriptions()
        }
        let participants = await self.state.callParticipants
        onParticipantsUpdated?(participants)
    }
    
    private func handleNegotiationNeeded() -> ((PeerConnection) -> Void) {
        { [weak self] peerConnection in
            guard let self = self else { return }
            Task {
                try? await self.negotiate(peerConnection: peerConnection)
            }
        }
    }
        
    private func negotiate(peerConnection: PeerConnection?) async throws {
        guard let peerConnection else { return }
        log.debug("Negotiating peer connection")
        let initialOffer = try await peerConnection.createOffer()
        log.debug("Setting local description for peer connection")
        var updatedSdp = initialOffer.sdp
        if audioSettings.opusDtxEnabled {
            log.debug("Setting Opus DTX for the audio")
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
        let sdp: String
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = offer.sdp
        request.sessionID = sessionID
        var tracks = [Stream_Video_Sfu_Models_TrackInfo]()
        if callSettings.videoOn {
            var layers = [Stream_Video_Sfu_Models_VideoLayer]()
            for codec in videoOptions.supportedCodecs {
                var layer = Stream_Video_Sfu_Models_VideoLayer()
                layer.bitrate = UInt32(codec.maxBitrate)
                layer.rid = codec.quality
                var dimension = Stream_Video_Sfu_Models_VideoDimension()
                dimension.height = UInt32(codec.dimensions.height)
                dimension.width = UInt32(codec.dimensions.width)
                layer.videoDimension = dimension
                layer.fps = 30
                layers.append(layer)
            }
            var videoTrack = Stream_Video_Sfu_Models_TrackInfo()
            videoTrack.trackID = localVideoTrack?.trackId ?? ""
            videoTrack.layers = layers
            videoTrack.trackType = .video
            tracks.append(videoTrack)
        }
        if callSettings.audioOn {
            var audioTrack = Stream_Video_Sfu_Models_TrackInfo()
            audioTrack.trackID = localAudioTrack?.trackId ?? ""
            audioTrack.trackType = .audio
            tracks.append(audioTrack)
        }
        request.tracks = tracks
        let response = try await signalService.setPublisher(setPublisherRequest: request)
        sdp = response.sdp
        log.debug("Setting remote description")
        try await peerConnection.setRemoteDescription(sdp, type: .answer)
    }
    
    private func makeAudioTrack() async -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = await peerConnectionFactory.makeAudioSource(audioConstrains)
        let audioTrack = await peerConnectionFactory.makeAudioTrack(source: audioSource)
        return audioTrack
    }
    
    private func makeVideoTrack(screenshare: Bool = false) async -> RTCVideoTrack {
        let videoSource = await peerConnectionFactory.makeVideoSource(forScreenShare: screenshare)
        videoCapturer = VideoCapturer(
            videoSource: videoSource,
            videoOptions: videoOptions,
            videoFilters: videoConfig.videoFilters
        )
        startCapturingLocalVideo(cameraPosition: callSettings.cameraPosition == .front ? .front : .back)
        let videoTrack = await peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }
    
    private func makeJoinRequest(subscriberSdp: String) -> Stream_Video_Sfu_Event_JoinRequest {
        log.debug("Executing join request")
        var joinRequest = Stream_Video_Sfu_Event_JoinRequest()
        joinRequest.token = token
        joinRequest.sessionID = sessionID
        joinRequest.subscriberSdp = subscriberSdp
        return joinRequest
    }
    
    private func webSocketURL(from hostname: String) -> URL? {
        let host = URL(string: hostname)?.host ?? hostname
        let wsURLString = "wss://\(host)/ws"
        let wsURL = URL(string: wsURLString)
        return wsURL
    }
    
    private func makeWebSocketClient(url: URL, apiKey: APIKey) -> WebSocketClient {
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
                try await self.handleSocketConnected()
            }
        }
        webSocketClient.participantCountUpdated = { [weak self] participantCount in
            self?.onParticipantCountUpdated?(participantCount)
        }

        return webSocketClient
    }
    
    private func handleSocketConnected() async throws {
        guard let connectOptions = connectOptions,
              let localVideoTrack = localVideoTrack,
              let localAudioTrack = localAudioTrack else {
            return
        }
        let tempPeerConnection = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            callCid: callCid,
            configuration: connectOptions.rtcConfiguration,
            type: .subscriber,
            coordinatorClient: callCoordinatorController.coordinatorClient,
            signalService: signalService,
            videoOptions: videoOptions,
            reportsStats: false
        )
        
        tempPeerConnection.addTrack(
            localAudioTrack,
            streamIds: ["temp-audio"],
            trackType: .audio
        )
        tempPeerConnection.addTransceiver(
            localVideoTrack,
            streamIds: ["temp-video"],
            direction: .recvOnly,
            trackType: .video
        )
        let offer = try await tempPeerConnection.createOffer()
        tempPeerConnection.transceiver?.stopInternal()
        tempPeerConnection.close()
        let payload = makeJoinRequest(subscriberSdp: offer.sdp)
        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .joinRequest(payload)
        signalChannel?.engine?.send(message: event)
    }
    
    private func updateParticipantsSubscriptions() async {
        var request = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        var tracks = [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]()
        request.sessionID = sessionID
        let callParticipants = await state.callParticipants
        for (_, value) in callParticipants {
            if value.id != sessionID {
                if value.hasVideo {
                    log.debug("updating video subscription for user \(value.id) with size \(value.trackSize)")
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
        let connectionState = await state.connectionState
        if connectionState == .connected && !tracks.isEmpty {
            request.tracks = tracks
            _ = try? await signalService.updateSubscriptions(
                updateSubscriptionsRequest: request
            )
        }
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
                screenshareTrack = subscriber?.findScreensharingTrack(
                    for: participant.trackLookupPrefix
                )
                if screenshareTrack != nil {
                    await state.add(
                        screensharingTrack: screenshareTrack,
                        id: participant.trackLookupPrefix ?? participant.id
                    )
                }
            }
            var updated: CallParticipant?
            if track != nil && participant.track == nil {
                updated = participant.withUpdated(track: track)
            }
            if screenshareTrack != nil && participant.screenshareTrack == nil {
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
                log.debug("received participant event")
                await self.handleParticipantsUpdated()
            }
        }
    }
    
    private func hasCapability(_ ownCapability: OwnCapability) -> Bool {
        callCoordinatorController
            .currentCallSettings?
            .callCapabilities
            .contains(ownCapability.rawValue) == true
    }
}

extension WebRTCClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        onSignalConnectionStateChange?(state)        
    }
}
