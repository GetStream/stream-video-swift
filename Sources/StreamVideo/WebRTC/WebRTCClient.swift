//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@preconcurrency import WebRTC

class WebRTCClient: NSObject {
    
    actor State: ObservableObject {
        private var cancellables = Set<AnyCancellable>()
        
        var connectionState = ConnectionState.disconnected(reason: nil)
        @Published var callParticipants = [String: CallParticipant]()
        var tracks = [String: RTCVideoTrack]()
        
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
        
        func callParticipantsUpdates() -> AsyncStream<[Bool]> {
            let updates = AsyncStream([Bool].self) { continuation in
                $callParticipants.sink { _ in
                    continuation.yield([true])
                }
                .store(in: &cancellables)
            }
            return updates
        }
    }
    
    let state = State()
    
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
    
    private var sessionID = UUID().uuidString
    private let token: String
    private let timeoutInterval: TimeInterval = 15
    
    // Video tracks.
    private var videoCapturer: VideoCapturer?
    private var localVideoTrack: RTCVideoTrack? {
        didSet {
            onLocalVideoTrackUpdate?(localVideoTrack)
        }
    }

    private var localAudioTrack: RTCAudioTrack?
    private let userInfo: UserInfo
    private var callSettings = CallSettings()
    private var videoOptions = VideoOptions()
    private let audioSession = AudioSession()
    private let participantsThreshold = 4
    
    var onLocalVideoTrackUpdate: ((RTCVideoTrack?) -> Void)?
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
        userInfo: userInfo,
        state: state,
        signalService: signalService,
        subscriber: subscriber,
        publisher: publisher,
        onParticipantEvent: onParticipantEvent
    )
    
    init(
        userInfo: UserInfo,
        apiKey: String,
        hostname: String,
        token: String,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userInfo = userInfo
        self.token = token
        httpClient = URLSessionClient(
            urlSession: StreamVideo.makeURLSession(),
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
        log.debug("Connecting to SFU")
        await state.update(connectionState: .connecting)
        log.debug("Connecting WS channel")
        signalChannel?.connect()
        log.debug("Creating subscriber peer connection")
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
        
        log.debug("Creating data channel")
        
        log.debug("Updating connection status to connected")
        await state.update(connectionState: .connected)
        if callSettings.shouldPublish {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration,
                type: .publisher,
                signalService: signalService,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
        }
        await setupUserMedia(callSettings: callSettings)
    }
    
    func cleanUp() async {
        callSettings = CallSettings()
        publisher = nil
        subscriber = nil
        signalChannel?.disconnect {}
        signalChannel = nil
        localAudioTrack = nil
        localVideoTrack = nil
        sessionID = UUID().uuidString
        await state.update(callParticipants: [:])
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
        await state.add(track: localVideoTrack, id: userInfo.id)
        
        if callSettings.shouldPublish {
            log.debug("publishing local tracks")
            publisher?.addTrack(audioTrack, streamIds: ["\(sessionID):audio"])
            publisher?.addTransceiver(videoTrack, streamIds: ["\(sessionID):video"])
        }
    }
    
    func changeAudioState(isEnabled: Bool) async throws {
        var request = Stream_Video_Sfu_Signal_UpdateMuteStateRequest()
        var muteChanged = Stream_Video_Sfu_Signal_AudioMuteChanged()
        muteChanged.muted = !isEnabled
        request.audioMuteChanged = muteChanged
        request.sessionID = sessionID
        _ = try await signalService.updateMuteState(updateMuteStateRequest: request)
        localAudioTrack?.isEnabled = isEnabled
    }
    
    func changeVideoState(isEnabled: Bool) async throws {
        var request = Stream_Video_Sfu_Signal_UpdateMuteStateRequest()
        var muteChanged = Stream_Video_Sfu_Signal_VideoMuteChanged()
        muteChanged.muted = !isEnabled
        request.videoMuteChanged = muteChanged
        request.sessionID = sessionID
        _ = try await signalService.updateMuteState(updateMuteStateRequest: request)
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
    
    // MARK: - private
    
    private func handleStreamAdded(_ stream: RTCMediaStream) {
        let idParts = stream.streamId.components(separatedBy: ":")
        let trackId = idParts.first ?? UUID().uuidString
        let track = stream.videoTracks.first
        Task {
            var videoTrack: RTCVideoTrack?
            if idParts.last == "video" && track != nil {
                videoTrack = track
                await self.state.add(track: videoTrack, id: trackId)
            }
            let participants = await state.callParticipants
            var participant: CallParticipant?
            for (_, callParticipant) in participants {
                if callParticipant.trackLookupPrefix == trackId || callParticipant.id == trackId {
                    participant = callParticipant
                    break
                }
            }
            if participant == nil {
                participant = CallParticipant(
                    id: trackId,
                    role: "member",
                    name: trackId,
                    profileImageURL: nil,
                    trackLookupPrefix: trackId,
                    isOnline: true,
                    hasVideo: true,
                    hasAudio: true,
                    showTrack: true
                )
            }
            if track != nil {
                participant?.track = track
            }
            if let participant = participant {
                await self.state.update(callParticipant: participant)
            }
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
        await updateParticipantsSubscriptions()
        let participants = await state.callParticipants
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
        videoCapturer = VideoCapturer(videoSource: videoSource, videoOptions: videoOptions)
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
            temp[participant.user.id] = participant.toCallParticipant(showTrack: showTrack)
        }
        await state.update(callParticipants: temp)
    }
    
    private func makeJoinRequest() -> Stream_Video_Sfu_Event_JoinRequest {
        log.debug("Executing join request")

        var videoCodecs = Stream_Video_Sfu_Models_VideoCodecs()
        videoCodecs.encodes = PeerConnectionFactory.supportedVideoCodecEncoding.map { $0.toSfuCodec() }
        videoCodecs.decodes = PeerConnectionFactory.supportedVideoCodecDecoding.map { $0.toSfuCodec() }

        var codecSettings = Stream_Video_Sfu_Models_CodecSettings()
        codecSettings.video = videoCodecs

        var layers = [Stream_Video_Sfu_Models_VideoLayer]()

        for codec in videoOptions.supportedCodecs {
            var layer = Stream_Video_Sfu_Models_VideoLayer()
            layer.bitrate = UInt32(codec.maxBitrate)
            layer.rid = codec.quality
            var dimension = Stream_Video_Sfu_Models_VideoDimension()
            dimension.height = UInt32(codec.dimensions.height)
            dimension.width = UInt32(codec.dimensions.width)
            layer.videoDimension = dimension
            layers.append(layer)
        }

        codecSettings.layers = layers

        var joinRequest = Stream_Video_Sfu_Event_JoinRequest()
        joinRequest.token = token
        joinRequest.sessionID = sessionID
        joinRequest.codecSettings = codecSettings
        joinRequest.publish = true // TODO: check this
        return joinRequest
    }
    
    private func webSocketURL(from hostname: String) -> URL? {
        let host = URL(string: hostname)?.host ?? hostname
        let wsURLString = "ws://\(host):3031/ws"
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
            let payload = self.makeJoinRequest()
            var event = Stream_Video_Sfu_Event_SfuRequest()
            event.requestPayload = .joinRequest(payload)
            webSocketClient.engine?.send(message: event)
        }
        
        webSocketClient.set(
            callInfo: [WebSocketConstants.sessionId: sessionID]
        )
        
        return webSocketClient
    }
    
    private func updateParticipantsSubscriptions() async {
        var request = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        var subscriptions = [String: Stream_Video_Sfu_Models_VideoDimension]()
        request.sessionID = sessionID
        let callParticipants = await state.callParticipants
        for (_, value) in callParticipants {
            if value.id != userInfo.id && value.showTrack {
                log.debug("updating subscription for user \(value.id) with size \(value.trackSize)")
                var dimension = Stream_Video_Sfu_Models_VideoDimension()
                dimension.height = UInt32(value.trackSize.height)
                dimension.width = UInt32(value.trackSize.width)
                subscriptions[value.id] = dimension
            }
        }
        
        request.subscriptions = subscriptions
        _ = try? await signalService.updateSubscriptions(
            updateSubscriptionsRequest: request
        )
    }
    
    private func assignTracksToParticipants() async {
        let callParticipants = await state.callParticipants
        for (_, participant) in callParticipants {
            var track: RTCVideoTrack?
            if let trackId = participant.trackLookupPrefix {
                track = await state.tracks[trackId]
            }
            if track == nil {
                track = await state.tracks[participant.id]
            }
            if track != nil && participant.track == nil {
                let updated = participant.withUpdated(track: track)
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
