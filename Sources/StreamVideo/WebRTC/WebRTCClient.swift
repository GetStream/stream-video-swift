//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class WebRTCClient: NSObject {
    
    // TODO: check if this state is really needed.
    actor State {
        var connectionStatus = VideoConnectionStatus.disconnected(reason: nil)
        
        func update(connectionStatus: VideoConnectionStatus) {
            self.connectionStatus = connectionStatus
        }
    }
    
    var state = State()
    
    let httpClient: HTTPClient
    let signalService: Stream_Video_Sfu_SignalServer
    let peerConnectionFactory = PeerConnectionFactory()
    
    private(set) var publisher: PeerConnection?
    private(set) var subscriber: PeerConnection?
    
    private(set) var signalChannel: DataChannel?
    
    // TODO: fix this
    private var sessionID = UUID().uuidString
    private let timeoutInterval: TimeInterval = 8
    
    // Video tracks.
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack? {
        didSet {
            onLocalVideoTrackUpdate?(localVideoTrack)
        }
    }

    private var localAudioTrack: RTCAudioTrack?
    private var userInfo: UserInfo
    
    private var callParticipants = [String: CallParticipant]() {
        didSet {
            updateParticipantsSubscriptions()
            onParticipantsUpdated?(callParticipants)
        }
    }
    
    var onLocalVideoTrackUpdate: ((RTCVideoTrack?) -> Void)?
    var onRemoteStreamAdded: ((RTCMediaStream?) -> Void)?
    var onRemoteStreamRemoved: ((RTCMediaStream?) -> Void)?
    var onParticipantsUpdated: (([String: CallParticipant]) -> Void)?
    
    init(
        userInfo: UserInfo,
        apiKey: String,
        hostname: String,
        token: String,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userInfo = userInfo
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
    }
    
    // TODO: connectOptions / roomOptions
    func connect(shouldPublish: Bool) async throws {
        await cleanUp()
        let connectionStatus = await state.connectionStatus
        if connectionStatus == .connected || connectionStatus == .connecting {
            log.debug("Skipping connection, already connected or connecting")
            return
        }
        log.debug("Connecting to SFU")
        await state.update(connectionStatus: .connecting)
        log.debug("Creating subscriber peer connection")
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        subscriber = try await peerConnectionFactory.makePeerConnection(
            sessionId: sessionID,
            configuration: configuration, // TODO: move this in connect options
            type: .subscriber,
            signalService: signalService
        )
        
        subscriber?.onStreamAdded = onRemoteStreamAdded
        subscriber?.onStreamRemoved = onRemoteStreamRemoved
        
        log.debug("Creating data channel")
        
        signalChannel = try subscriber?.makeDataChannel(label: "signaling")
        signalChannel?.onEventReceived = { [weak self] event in
            self?.handle(event: event)
        }
        
        try await join(peerConnection: subscriber)
        try await listenForConnectionOpened()
        log.debug("Updating connection status to connected")
        await state.update(connectionStatus: .connected)
        if shouldPublish {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration, // TODO: move this in connect options
                type: .publisher,
                signalService: signalService
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
        }
        // TODO: pass call settings
        await setupUserMedia(callSettings: CallSettings(), shouldPublish: shouldPublish)
    }
    
    func startCapturingLocalVideo(renderer: RTCVideoRenderer, cameraPosition: AVCaptureDevice.Position) {
        setCameraPosition(cameraPosition)
        localVideoTrack?.add(renderer)
    }
    
    private func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) {
        guard let capturer = videoCapturer as? RTCCameraVideoCapturer else { return }
        
        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == cameraPosition }),
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
        
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { $0.maxFrameRate < $1.maxFrameRate }.last) else {
            return
        }

        capturer.startCapture(
            with: frontCamera,
            format: format,
            fps: Int(fps.maxFrameRate)
        )
    }
    
    func changeCameraMode(position: CameraPosition) {
        setCameraPosition(position == .front ? .front : .back)
    }
    
    func setupUserMedia(callSettings: CallSettings, shouldPublish: Bool) async {
        configureAudioSession(isActive: callSettings.audioOn)
        
        // Audio
        let audioTrack = await makeAudioTrack()
        localAudioTrack = audioTrack
        
        // Video
        let videoTrack = await makeVideoTrack()
        localVideoTrack = videoTrack
        
        if shouldPublish {
            log.debug("publishing local tracks")
            publisher?.addTrack(audioTrack, streamIds: [sessionID])
            publisher?.addTransceiver(videoTrack, streamIds: [sessionID])
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
    
    func configureAudioSession(
        _ configuration: RTCAudioSessionConfiguration = .default,
        isActive: Bool = false
    ) {
        let audioSession: RTCAudioSession = RTCAudioSession.sharedInstance()
        audioSession.lockForConfiguration()

        defer { audioSession.unlockForConfiguration() }

        do {
            log.debug("Configuring audio session")
            try audioSession.setConfiguration(configuration, active: isActive)
        } catch {
            log.error("Error occured while configuring audio session \(error)")
        }
    }
    
    private func handleNegotiationNeeded() -> ((PeerConnection) -> Void) {
        { [weak self] peerConnection in
            guard let self = self else { return }
            Task {
                try? await self.negotiate(peerConnection: peerConnection)
            }
        }
    }
    
    private func join(peerConnection: PeerConnection?) async throws {
        log.debug("Creating peer connection offer")
        let offer = try await peerConnection?.createOffer()
        log.debug("Setting local description for peer connection")
        try await peerConnection?.setLocalDescription(offer)
        let joinResponse = try await executeJoinRequest(for: offer)
        callParticipants = loadParticipants(from: joinResponse)
        let sdp = joinResponse.sdp
        log.debug("Setting remote description")
        try await peerConnection?.setRemoteDescription(sdp, type: .answer)
    }
    
    private func negotiate(peerConnection: PeerConnection?) async throws {
        log.debug("Creating peer connection offer")
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
        
        #if targetEnvironment(simulator)
        videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = await peerConnectionFactory.makeVideoTrack(source: videoSource)
        return videoTrack
    }
    
    private func loadParticipants(from response: Stream_Video_Sfu_JoinResponse) -> [String: CallParticipant] {
        let participants = response.callState.participants
        var temp = [String: CallParticipant]()
        for participant in participants {
            temp[participant.user.id] = participant.toCallParticipant()
        }
        return temp
    }
    
    private func executeJoinRequest(
        for subscriberOffer: RTCSessionDescription?
    ) async throws -> Stream_Video_Sfu_JoinResponse {
        log.debug("Executing join request")
        var joinRequest = Stream_Video_Sfu_JoinRequest()
        joinRequest.subscriberSdpOffer = subscriberOffer?.sdp ?? ""
        joinRequest.sessionID = sessionID
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
        if let event = event as? Stream_Video_Sfu_SubscriberOffer {
            handleSubscriberEvent(event)
        } else if let event = event as? Stream_Video_Sfu_ParticipantJoined {
            handleParticipantJoined(event)
        } else if let event = event as? Stream_Video_Sfu_ParticipantLeft {
            handleParticipantLeft(event)
        } else if let event = event as? Stream_Video_Sfu_ChangePublishQuality {
            handleChangePublishQualityEvent(event)
        }
    }
    
    private func handleSubscriberEvent(_ event: Stream_Video_Sfu_SubscriberOffer) {
        Task {
            do {
                log.debug("Handling subscriber offer")
                let offerSdp = event.sdp
                try await self.subscriber?.setRemoteDescription(offerSdp, type: .offer)
                let answer = try await self.subscriber?.createAnswer()
                try await self.subscriber?.setLocalDescription(answer)
                var sendAnswerRequest = Stream_Video_Sfu_SendAnswerRequest()
                sendAnswerRequest.sessionID = self.sessionID
                sendAnswerRequest.peerType = .subscriber
                sendAnswerRequest.sdp = answer?.sdp ?? ""
                log.debug("Sending answer for offer")
                _ = try await self.signalService.sendAnswer(sendAnswerRequest: sendAnswerRequest)
            } catch {
                log.error("Error handling offer event \(error.localizedDescription)")
            }
        }
    }
    
    private func handleParticipantJoined(_ event: Stream_Video_Sfu_ParticipantJoined) {
        let participant = event.participant.toCallParticipant()
        callParticipants[participant.id] = participant
    }
    
    private func handleParticipantLeft(_ event: Stream_Video_Sfu_ParticipantLeft) {
        let participant = event.participant.toCallParticipant()
        callParticipants.removeValue(forKey: participant.id)
    }
    
    private func updateParticipantsSubscriptions() {
        // TODO: implement updates of view sizes.
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        Task {
            var request = Stream_Video_Sfu_UpdateSubscriptionsRequest()
            var subscriptions = [String: Stream_Video_Sfu_VideoDimension]()
            request.sessionID = sessionID
            for (_, value) in callParticipants {
                if value.id != userInfo.id {
                    log.debug("updating subscription for user \(value.id)")
                    var dimension = Stream_Video_Sfu_VideoDimension()
                    dimension.height = UInt32(screenHeight) // TODO: only temp!
                    dimension.width = UInt32(screenWidth) // TODO: only temp!
                    subscriptions[value.id] = dimension
                }
            }
            request.subscriptions = subscriptions
            _ = try? await signalService.updateSubscriptions(
                updateSubscriptionsRequest: request
            )
        }
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
    
    private func cleanUp() async {}
}

extension RTCAudioSessionConfiguration {
    
    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration.webRTC()
        configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        return configuration
    }()
}
