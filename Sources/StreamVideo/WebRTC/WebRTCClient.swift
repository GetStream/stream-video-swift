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
    let signalService: Stream_Video_SignalServer
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
    
    var onLocalVideoTrackUpdate: ((RTCVideoTrack?) -> Void)?
    var onRemoteStreamAdded: ((RTCMediaStream?) -> Void)?
    var onRemoteStreamRemoved: ((RTCMediaStream?) -> Void)?
    
    init(
        apiKey: String,
        hostname: String,
        token: String,
        tokenProvider: @escaping TokenProvider
    ) {
        httpClient = URLSessionClient(
            urlSession: StreamVideo.makeURLSession(),
            tokenProvider: tokenProvider
        )
        
        signalService = Stream_Video_SignalServer(
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
        
        try await negotiate(peerConnection: subscriber, shouldJoin: true)
        if shouldPublish {
            publisher = try await peerConnectionFactory.makePeerConnection(
                sessionId: sessionID,
                configuration: configuration, // TODO: move this in connect options
                type: .publisher,
                signalService: signalService
            )
            publisher?.onNegotiationNeeded = handleNegotiationNeeded()
        }
        try await listenForConnectionOpened()
        log.debug("Updating connection status to connected")
        await state.update(connectionStatus: .connected)
        // TODO: pass call settings
        await setupUserMedia(callSettings: CallSettings(), shouldPublish: shouldPublish)
    }
    
    func startCapturingLocalVideo(renderer: RTCVideoRenderer, cameraPosition: AVCaptureDevice.Position) {
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
        
        localVideoTrack?.add(renderer)
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
                try? await self.negotiate(peerConnection: peerConnection, shouldJoin: false)
            }
        }
    }
    
    private func negotiate(peerConnection: PeerConnection?, shouldJoin: Bool) async throws {
        log.debug("Creating peer connection offer")
        let offer = try await peerConnection?.createOffer()
        log.debug("Setting local description for peer connection")
        try await peerConnection?.setLocalDescription(offer)
        let sdp: String
        if shouldJoin {
            let joinResponse = try await executeJoinRequest(for: offer)
            sdp = joinResponse.sdp
        } else {
            var request = Stream_Video_SetPublisherRequest()
            request.sdp = offer?.sdp ?? ""
            request.sessionID = sessionID
            let response = try await signalService.setPublisher(setPublisherRequest: request)
            sdp = response.sdp
        }
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
    
    private func executeJoinRequest(
        for subscriberOffer: RTCSessionDescription?
    ) async throws -> Stream_Video_JoinResponse {
        log.debug("Executing join request")
        var joinRequest = Stream_Video_JoinRequest()
        joinRequest.subscriberSdpOffer = subscriberOffer?.sdp ?? ""
        joinRequest.sessionID = sessionID
        // TODO: this will return call state (list of participants)
        // TODO: Need to ask for track with updateSubscriptions
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
        // TODO: new participant events for leave / join
        if let event = event as? Stream_Video_SubscriberOffer {
            Task {
                do {
                    log.debug("Handling subscriber offer")
                    let offerSdp = event.sdp
                    try await self.subscriber?.setRemoteDescription(offerSdp, type: .offer)
                    let answer = try await self.subscriber?.createOffer()
                    try await self.subscriber?.setLocalDescription(answer)
                    var sendAnswerRequest = Stream_Video_SendAnswerRequest()
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
    }
    
    private func cleanUp() async {}
}

extension RTCAudioSessionConfiguration {
    
    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration()
        configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        return configuration
    }()
}
