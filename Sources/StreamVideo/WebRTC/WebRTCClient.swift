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
        
        private var enrichedUserData = [String: EnrichedUserData]()
        private let callCoordinatorController: CallCoordinatorController
        
        init(callCoordinatorController: CallCoordinatorController) {
            self.callCoordinatorController = callCoordinatorController
        }
        
        var connectionState = ConnectionState.disconnected(reason: nil)
        @Published var callParticipants = [String: CallParticipant]()
        var tracks = [String: RTCVideoTrack]()
        var screensharingTracks = [String: RTCVideoTrack]()
        
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
                $callParticipants.sink { _ in
                    continuation.yield([true])
                }
                .store(in: &cancellables)
            }
            return updates
        }
        
        func enrichedData(for userId: String) async -> EnrichedUserData {
            if let data = enrichedUserData[userId] {
                return data
            }
            let enrichedData = try? await callCoordinatorController.enrichUserData(for: userId)
            enrichedUserData[userId] = enrichedData
            return enrichedData ?? .empty
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
    
    private var signalChannel: WebSocketClient?
    
    private(set) var sessionID = UUID().uuidString
    private let token: String
    private let timeoutInterval: TimeInterval = 15
    
    // Video tracks.
    private var videoCapturer: VideoCapturer?
    private var localVideoTrack: RTCVideoTrack?

    private var localAudioTrack: RTCAudioTrack?
    private let user: User
    private let callCid: String
    private var videoOptions = VideoOptions()
    private let audioSession = AudioSession()
    private let participantsThreshold = 8
    private var connectOptions: ConnectOptions?
    private var callSettings = CallSettings()
    private let callCoordinatorController: CallCoordinatorController
    private let videoConfig: VideoConfig
    
    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    var onParticipantEvent: ((ParticipantEvent) -> Void)? {
        didSet {
            sfuMiddleware.onParticipantEvent = onParticipantEvent
        }
    }
    
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
        token: String,
        callCid: String,
        callCoordinatorController: CallCoordinatorController,
        videoConfig: VideoConfig,
        tokenProvider: @escaping UserTokenProvider
    ) {
        state = State(callCoordinatorController: callCoordinatorController)
        self.user = user
        self.token = token
        self.callCid = callCid
        self.videoConfig = videoConfig
        self.callCoordinatorController = callCoordinatorController
        httpClient = URLSessionClient(
            urlSession: StreamVideo.Environment.makeURLSession(),
            tokenProvider: tokenProvider
        )
        
        signalService = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
        super.init()
        if let url = webSocketURL(from: hostname) {
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
        signalChannel?.disconnect {}
        signalChannel = nil
        localAudioTrack = nil
        localVideoTrack = nil
        sessionID = UUID().uuidString
        await state.update(callParticipants: [:])
        await state.update(tracks: [:])
        await state.update(screensharingTracks: [:])
        await state.update(connectionState: .disconnected(reason: .user))
    }
    
    func startCapturingLocalVideo(renderer: RTCVideoRenderer, cameraPosition: AVCaptureDevice.Position) {
        setCameraPosition(cameraPosition)
    }
    
    func changeCameraMode(position: CameraPosition) {
        setCameraPosition(position == .front ? .front : .back)
    }
    
    func setupUserMedia(callSettings: CallSettings) async {
        await audioSession.configure(callSettings: callSettings)
        
        // Audio
        let audioTrack = await makeAudioTrack()
        localAudioTrack = audioTrack
        
        // Video
        let videoTrack = await makeVideoTrack()
        localVideoTrack = videoTrack
        await state.add(track: localVideoTrack, id: sessionID)
    }
    
    func publishUserMedia(callSettings: CallSettings) {
        if callSettings.shouldPublish, let audioTrack = localAudioTrack {
            log.debug("publishing local tracks")
            publisher?.addTrack(audioTrack, streamIds: ["\(sessionID):audio"])
            if videoConfig.videoEnabled, let videoTrack = localVideoTrack {
                publisher?.addTransceiver(videoTrack, streamIds: ["\(sessionID):video"])
            }
        }
    }
    
    func changeAudioState(isEnabled: Bool) async throws {
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
        var request = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        var video = Stream_Video_Sfu_Signal_TrackMuteState()
        video.trackType = .video
        video.muted = !isEnabled
        request.muteStates = [video]
        request.sessionID = sessionID
        _ = try await signalService.updateMuteStates(updateMuteStatesRequest: request)
        localVideoTrack?.isEnabled = isEnabled
    }
    
    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        guard let participant = await state.callParticipants[participant.id],
              participant.showTrack != isVisible else {
            return
        }
        log.debug("Setting track for \(participant.name) to \(isVisible)")
        let updated = participant.withUpdated(showTrack: isVisible)
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
            coordinatorService: callCoordinatorController.callCoordinatorService,
            signalService: signalService,
            videoOptions: videoOptions
        )
        
        subscriber?.onStreamAdded = handleStreamAdded
        subscriber?.onStreamRemoved = handleStreamRemoved
        
        log.debug("Updating connection status to connected")
        await state.update(connectionState: .connected)
        signalChannel?.engine?.send(message: Stream_Video_Sfu_Event_HealthCheckRequest())
        if callSettings.shouldPublish {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                callCid: callCid,
                configuration: configuration,
                type: .publisher,
                coordinatorService: callCoordinatorController.callCoordinatorService,
                signalService: signalService,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
            publishUserMedia(callSettings: callSettings)
        }
    }
    
    private func handleStreamAdded(_ stream: RTCMediaStream) {
        let idParts = stream.streamId.components(separatedBy: ":")
        let trackId = idParts.first ?? UUID().uuidString
        let track = stream.videoTracks.first
        Task {
            let last = idParts.last
            if videoConfig.videoEnabled && last == Constants.videoTrackType && track != nil {
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
    
    private func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) {
        guard let capturer = videoCapturer else { return }
        capturer.setCameraPosition(cameraPosition)
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
        log.debug("Negotiating peer connection")
        let offer = try await peerConnection?.createOffer()
        log.debug("Setting local description for peer connection")
        try await peerConnection?.setLocalDescription(offer)
        let sdp: String
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = offer?.sdp ?? ""
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
        try await peerConnection?.setRemoteDescription(sdp, type: .answer)
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
        let videoTrack = await peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }
    
    private func loadParticipants(from response: Stream_Video_Sfu_Event_JoinResponse) async {
        log.debug("Loading participants from joinResponse")
        let participants = response.callState.participants
        // For more than threshold participants, the activation of track is on view appearance.
        let showTrack = participants.count < participantsThreshold
        var temp = [String: CallParticipant]()
        for participant in participants {
            let enrichedData = await state.enrichedData(for: participant.userID)
            temp[participant.userID] = participant.toCallParticipant(
                showTrack: showTrack,
                enrichData: enrichedData
            )
        }
        await state.update(callParticipants: temp)
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
        var wsURLString = "wss://\(host)/ws"
        if host.starts(with: "192.") || host.starts(with: "localhost") {
            // Temporary for localhost testing.
            wsURLString = "ws://\(host):3031/ws"
        }
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
            connectURL: url,
            requiresAuth: false
        )
        
        webSocketClient.onConnect = { [weak self] in
            guard let self = self else { return }
            Task {
                try await self.handleSocketConnected()
            }
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
            coordinatorService: callCoordinatorController.callCoordinatorService,
            signalService: signalService,
            videoOptions: videoOptions,
            reportsStats: false
        )
        
        tempPeerConnection.addTrack(localAudioTrack, streamIds: ["temp-audio"])
        tempPeerConnection.addTransceiver(localVideoTrack, streamIds: ["temp-video"], direction: .recvOnly)
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
                if screenshareTrack == nil {
                    screenshareTrack = await state.screensharingTracks[participant.id]
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
}
