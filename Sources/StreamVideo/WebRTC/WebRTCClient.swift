//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

class WebRTCClient: NSObject {
    
    actor State {
        var onParticipantsUpdated: (() -> Void)?
        
        var connectionStatus = VideoConnectionStatus.disconnected(reason: nil)
        var callParticipants = [String: CallParticipant]() {
            didSet {
                onParticipantsUpdated?()
            }
        }
        var tracks = [String: RTCVideoTrack]()
        
        func update(connectionStatus: VideoConnectionStatus) {
            self.connectionStatus = connectionStatus
        }
        
        func update(callParticipants: [String: CallParticipant]) {
            self.callParticipants = callParticipants
        }
        
        func update(callParticipant: CallParticipant) {
            self.callParticipants[callParticipant.id] = callParticipant
        }
        
        func remove(callParticipant: CallParticipant) {
            self.callParticipants.removeValue(forKey: callParticipant.id)
        }
        
        func update(tracks: [String: RTCVideoTrack]) {
            self.tracks = tracks
        }
        
        func add(track: RTCVideoTrack?, id: String) {
            self.tracks[id] = track
        }
        
        func addOnParticipantsHandler(_ handler: @escaping () -> Void) {
            self.onParticipantsUpdated = handler
        }
    }
    
    var state = State()
    
    let httpClient: HTTPClient
    let signalService: Stream_Video_Sfu_SignalServer
    let peerConnectionFactory = PeerConnectionFactory()
    
    private(set) var publisher: PeerConnection?
    private(set) var subscriber: PeerConnection?
    
    private(set) var signalChannel: DataChannel?
    
    private var sessionID = UUID().uuidString
    private let timeoutInterval: TimeInterval = 15
    
    // Video tracks.
    private var videoCapturer: VideoCapturer?
    private var localVideoTrack: RTCVideoTrack? {
        didSet {
            onLocalVideoTrackUpdate?(localVideoTrack)
        }
    }

    private var localAudioTrack: RTCAudioTrack?
    private var userInfo: UserInfo
    private var callSettings = CallSettings()
    private var videoOptions = VideoOptions()
    private let audioSession = AudioSession()
    private let participantsThreshold = 4
    private var host: String
    
    var onLocalVideoTrackUpdate: ((RTCVideoTrack?) -> Void)?
    var onRemoteTrackAdded: ((RTCVideoTrack?, String) -> Void)?
    var onRemoteStreamRemoved: ((RTCMediaStream?) -> Void)?
    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    init(
        userInfo: UserInfo,
        apiKey: String,
        hostname: String,
        token: String,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userInfo = userInfo
        host = URL(string: hostname)?.host ?? hostname
        httpClient = URLSessionClient(
            urlSession: StreamVideo.makeURLSession(),
            tokenProvider: tokenProvider
        )
        
        signalService = Stream_Video_Sfu_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
        
        super.init()
        addOnParticipantsChangeHandler()
    }
    
    // TODO: connectOptions / roomOptions
    func connect(callSettings: CallSettings, videoOptions: VideoOptions) async throws {
        let connectionStatus = await state.connectionStatus
        if connectionStatus == .connected || connectionStatus == .connecting {
            log.debug("Skipping connection, already connected or connecting")
            return
        }
        await cleanUp()
        self.videoOptions = videoOptions
        log.debug("Connecting to SFU")
        await state.update(connectionStatus: .connecting)
        log.debug("Creating subscriber peer connection")
        let configuration = RTCConfiguration.makeConfiguration(with: host)
        subscriber = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: configuration, // TODO: move this in connect options
            type: .subscriber,
            signalService: signalService,
            videoOptions: videoOptions
        )
        
        subscriber?.onStreamAdded = { [weak self] stream in
            self?.handleStreamAdded(stream)
        }
        subscriber?.onStreamRemoved = onRemoteStreamRemoved
        
        log.debug("Creating data channel")
        
        signalChannel = try subscriber?.makeDataChannel(label: "signaling")
        signalChannel?.onEventReceived = { [weak self] event in
            self?.handle(event: event)
        }
        
        let participants = try await join(peerConnection: subscriber)
        try await listenForConnectionOpened()
        log.debug("Updating connection status to connected")
        await state.update(connectionStatus: .connected)
        if callSettings.shouldPublish {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration, // TODO: move this in connect options
                type: .publisher,
                signalService: signalService,
                videoOptions: videoOptions
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
        }
        await setupUserMedia(callSettings: callSettings)
        await state.update(callParticipants: participants)
    }
    
    func cleanUp() async {
        callSettings = CallSettings()
        publisher = nil
        subscriber = nil
        signalChannel = nil
        localAudioTrack = nil
        localVideoTrack = nil
        sessionID = UUID().uuidString
        await state.update(callParticipants: [:])
        await state.update(connectionStatus: .disconnected(reason: .user))
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
        var request = Stream_Video_Sfu_UpdateMuteStateRequest()
        var muteChanged = Stream_Video_Sfu_AudioMuteChanged()
        muteChanged.muted = !isEnabled
        request.audioMuteChanged = muteChanged
        request.sessionID = sessionID
        _ = try await signalService.updateMuteState(updateMuteStateRequest: request)
        localAudioTrack?.isEnabled = isEnabled
    }
    
    func changeVideoState(isEnabled: Bool) async throws {
        var request = Stream_Video_Sfu_UpdateMuteStateRequest()
        var muteChanged = Stream_Video_Sfu_VideoMuteChanged()
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
            if idParts.last == "video" || stream.videoTracks.first != nil {
                videoTrack = track
            }
            await self.state.add(track: videoTrack, id: trackId)
        }
        onRemoteTrackAdded?(track, trackId)
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
    
    private func join(peerConnection: PeerConnection?) async throws -> [String: CallParticipant] {
        log.debug("Creating peer connection offer")
        let offer = try await peerConnection?.createOffer()
        log.debug("Setting local description for peer connection")
        try await peerConnection?.setLocalDescription(offer)
        let joinResponse = try await executeJoinRequest(for: offer)
        let participants = loadParticipants(from: joinResponse)
        let sdp = joinResponse.sdp
        log.debug("Setting remote description")
        try await peerConnection?.setRemoteDescription(sdp, type: .answer)
        return participants
    }
    
    private func negotiate(peerConnection: PeerConnection?) async throws {
        log.debug("Negotiating peer connection")
        let offer = try await peerConnection?.createOffer()
        log.debug("Setting local description for peer connection")
        try await peerConnection?.setLocalDescription(offer)
        let sdp: String
        var request = Stream_Video_Sfu_SetPublisherRequest()
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
    
    private func loadParticipants(from response: Stream_Video_Sfu_JoinResponse) -> [String: CallParticipant] {
        let participants = response.callState.participants
        // For more than threshold participants, the activation of track is on view appearance.
        let showTrack = participants.count < participantsThreshold
        var temp = [String: CallParticipant]()
        for participant in participants {
            temp[participant.user.id] = participant.toCallParticipant(showTrack: showTrack)
        }
        return temp
    }
    
    private func executeJoinRequest(
        for subscriberOffer: RTCSessionDescription?
    ) async throws -> Stream_Video_Sfu_JoinResponse {
        log.debug("Executing join request")
                
        var videoCodecs = Stream_Video_Sfu_VideoCodecs()
        videoCodecs.encode = PeerConnectionFactory.supportedVideoCodecEncoding.map { $0.toSfuCodec() }
        videoCodecs.decode = PeerConnectionFactory.supportedVideoCodecDecoding.map { $0.toSfuCodec() }
        
        var codecSettings = Stream_Video_Sfu_CodecSettings()
        codecSettings.video = videoCodecs
        
        var layers = [Stream_Video_Sfu_VideoLayer]()
        
        for codec in videoOptions.supportedCodecs {
            var layer = Stream_Video_Sfu_VideoLayer()
            layer.bitrate = UInt32(codec.maxBitrate)
            layer.rid = codec.quality
            var dimension = Stream_Video_Sfu_VideoDimension()
            dimension.height = UInt32(codec.dimensions.height)
            dimension.width = UInt32(codec.dimensions.width)
            layer.videoDimension = dimension
            layers.append(layer)
        }
        
        codecSettings.layers = layers
        
        var joinRequest = Stream_Video_Sfu_JoinRequest()
        joinRequest.subscriberSdpOffer = subscriberOffer?.sdp ?? ""
        joinRequest.sessionID = sessionID
        joinRequest.codecSettings = codecSettings
        let response = try await signalService.join(joinRequest: joinRequest)
        return response
    }
    
    private func listenForConnectionOpened() async throws {
        var connected = false
        var timeout = false
        let control = DefaultTimer.schedule(timeInterval: timeoutInterval, queue: .sdk) {
            timeout = true
        }
        log.debug("Listening for subscriber data channel opening")
        signalChannel?.onStateChange = { [weak self] state in
            if state == .open {
                control.cancel()
                connected = true
                log.debug("Subscriber data channel opened")
                self?.signalChannel?.send(data: Data.sample)
            }
        }
        
        while (!connected && !timeout) {
            try await Task.sleep(nanoseconds: 100_000)
        }
        
        if timeout {
            log.debug("Timeout while waiting for data channel opening")
            throw ClientError.NetworkError()
        }
    }
    
    private func handle(event: Event) {
        log.debug("Received an event \(event)")
        Task {
            if let event = event as? Stream_Video_Sfu_SubscriberOffer {
                await handleSubscriberEvent(event)
            } else if let event = event as? Stream_Video_Sfu_ParticipantJoined {
                await handleParticipantJoined(event)
            } else if let event = event as? Stream_Video_Sfu_ParticipantLeft {
                await handleParticipantLeft(event)
            } else if let event = event as? Stream_Video_Sfu_ChangePublishQuality {
                handleChangePublishQualityEvent(event)
            } else if let event = event as? Stream_Video_Sfu_DominantSpeakerChanged {
                await handleDominantSpeakerChanged(event)
            } else if let event = event as? Stream_Video_Sfu_MuteStateChanged {
                await handleMuteStateChangedEvent(event)
            }
        }
    }
    
    private func handleSubscriberEvent(_ event: Stream_Video_Sfu_SubscriberOffer) async {
        do {
            log.debug("Handling subscriber offer")
            let offerSdp = event.sdp
            try await subscriber?.setRemoteDescription(offerSdp, type: .offer)
            let answer = try await subscriber?.createAnswer()
            try await subscriber?.setLocalDescription(answer)
            var sendAnswerRequest = Stream_Video_Sfu_SendAnswerRequest()
            sendAnswerRequest.sessionID = sessionID
            sendAnswerRequest.peerType = .subscriber
            sendAnswerRequest.sdp = answer?.sdp ?? ""
            log.debug("Sending answer for offer")
            _ = try await signalService.sendAnswer(sendAnswerRequest: sendAnswerRequest)
        } catch {
            log.error("Error handling offer event \(error.localizedDescription)")
        }
    }
    
    private func handleParticipantJoined(_ event: Stream_Video_Sfu_ParticipantJoined) async {
        let callParticipants = await state.callParticipants
        let showTrack = (callParticipants.count + 1) < participantsThreshold
        let participant = event.participant.toCallParticipant(showTrack: showTrack)
        await state.update(callParticipant: participant)
        let event = ParticipantEvent(
            id: participant.id,
            action: .join,
            user: participant.name,
            imageURL: participant.profileImageURL
        )
        log.debug("Participant \(participant.name) joined the call")
        onParticipantEvent?(event)
    }
    
    private func handleParticipantLeft(_ event: Stream_Video_Sfu_ParticipantLeft) async {
        let participant = event.participant.toCallParticipant()
        await state.remove(callParticipant: participant)
        let event = ParticipantEvent(
            id: participant.id,
            action: .leave,
            user: participant.name,
            imageURL: participant.profileImageURL
        )
        log.debug("Participant \(participant.name) left the call")
        onParticipantEvent?(event)
    }
    
    private func updateParticipantsSubscriptions() async {
        var request = Stream_Video_Sfu_UpdateSubscriptionsRequest()
        var subscriptions = [String: Stream_Video_Sfu_VideoDimension]()
        request.sessionID = sessionID
        let callParticipants = await state.callParticipants
        for (_, value) in callParticipants {
            if value.id != userInfo.id && value.showTrack {
                log.debug("updating subscription for user \(value.id) with size \(value.trackSize)")
                var dimension = Stream_Video_Sfu_VideoDimension()
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
    
    private func handleChangePublishQualityEvent(
        _ event: Stream_Video_Sfu_ChangePublishQuality
    ) {
        guard let transceiver = publisher?.transceiver else { return }
        let enabledRids = event.videoSender.first?.layers
            .filter { $0.active }
            .map(\.name) ?? []
        log.debug("Enabled rids = \(enabledRids)")
        let params = transceiver.sender.parameters
        var updatedEncodings = [RTCRtpEncodingParameters]()
        var changed = false
        log.debug("Current publish quality \(params)")
        for encoding in params.encodings {
            let shouldEnable = enabledRids.contains(encoding.rid ?? UUID().uuidString)
            if shouldEnable && encoding.isActive {
                updatedEncodings.append(encoding)
            } else if !shouldEnable && !encoding.isActive {
                updatedEncodings.append(encoding)
            } else {
                changed = true
                encoding.isActive = shouldEnable
                updatedEncodings.append(encoding)
            }
        }
        if changed {
            log.debug("Updating publish quality with encodings \(updatedEncodings)")
            params.encodings = updatedEncodings
            publisher?.transceiver?.sender.parameters = params
        }
    }
    
    private func handleDominantSpeakerChanged(_ event: Stream_Video_Sfu_DominantSpeakerChanged) async {
        let userId = event.userID
        var temp = [String: CallParticipant]()
        let callParticipants = await state.callParticipants
        for (key, participant) in callParticipants {
            let updated: CallParticipant
            if key == userId {
                updated = participant.withUpdated(
                    layoutPriority: .high,
                    isDominantSpeaker: true
                )
                log.debug("Participant \(participant.name) is the dominant speaker")
                resetDominantSpeaker(participant)
            } else {
                updated = participant.withUpdated(
                    layoutPriority: .normal,
                    isDominantSpeaker: false
                )
            }
            temp[key] = updated
        }
        await state.update(callParticipants: temp)
    }
    
    private func resetDominantSpeaker(_ participant: CallParticipant) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            let updated = participant.withUpdated(
                layoutPriority: .normal,
                isDominantSpeaker: false
            )
            Task {
                await self.state.update(callParticipant: updated)
            }
        }
    }
    
    private func assignTracksToParticipants() async {
        let callParticipants = await state.callParticipants
        for (key, participant) in callParticipants {
            let track = await state.tracks[key]
            if track != nil && participant.track == nil {
                let updated = participant.withUpdated(track: track)
                await state.update(callParticipant: updated)
            }
        }
    }
    
    private func addOnParticipantsChangeHandler() {
        Task {
            await state.addOnParticipantsHandler(onParticipantsHandler)
        }
    }
    
    private func onParticipantsHandler() {
        Task {
            await self.handleParticipantsUpdated()
        }
    }
    
    private func handleMuteStateChangedEvent(_ event: Stream_Video_Sfu_MuteStateChanged) async {
        let userId = event.userID
        guard let participant = await state.callParticipants[userId] else { return }
        var updated = participant.withUpdated(audio: !event.audioMuted)
        updated = updated.withUpdated(video: !event.videoMuted)
        await state.update(callParticipant: updated)
    }
}
