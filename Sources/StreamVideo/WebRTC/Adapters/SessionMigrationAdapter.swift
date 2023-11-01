//
//  SessionMigrationAdapter.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 1/11/23.
//

import Foundation
import WebRTC

final class SessionMigrationAdapter: EventMiddleware, Equatable {
    private enum State: Equatable {
        case ready
        case preparing
        case sendJoinRequest
        case joined
        case setUpSubscriber
        case publishLocalTracks
        case restartICE
        case waitingSubscriberOffer
        case setPublisher
        case setPublisherAnswer
        case completed
        case error(String)
    }

    typealias SignalServer = Stream_Video_Sfu_Signal_SignalServer
    typealias PeerConnectionFactory = (PeerConnectionType, SignalServer) async throws -> PeerConnection
    typealias JoinRequestFactory = (String, String, String) async -> Stream_Video_Sfu_Event_JoinRequest
    typealias DisconnectSignalChannel = (WebSocketClient, SignalServer) -> Void
    typealias PauseSubscriber = () -> Void
    typealias UpdateSubscriber = (PeerConnection) async -> Void
    typealias SetUpUserMedia = () async -> Void
    typealias PublishUserMedia = () -> Void
    typealias SetPublisher = (String, WebSocketClient, SignalServer) async throws-> String
    typealias SetPublisherAnswer = (String, WebSocketClient, SignalServer) async throws-> Void
    typealias Completed = () -> Void

    let identifier: UUID = .init()
    let fromSFU: String
    let sessionID: String
    let callSettings: CallSettings
    let audioSettings: AudioSettings
    let publisher: PeerConnection
    let httpClient: HTTPClient
    let apiKey: String
    let eventNotificationCenter: EventNotificationCenter
    let environment: WebSocketClient.Environment
    let signalServerHostname: String
    let signalServerToken: String
    let signalWSClientConnectURL: String
    let connectOptions: ConnectOptions
    let audioTrack: RTCAudioTrack?
    let videoTrack: RTCVideoTrack?
    let sfu: SfuMiddleware
    private(set) weak var connectionStateDelegate: ConnectionStateDelegate?
    let peerConnectionFactory: PeerConnectionFactory
    let joinRequestFactory: JoinRequestFactory
    let disconnectSignalChannel: DisconnectSignalChannel
    let pauseSubscriber: PauseSubscriber
    let updateSubscriber: UpdateSubscriber
    let setUpUserMedia: SetUpUserMedia
    let publishUserMedia: PublishUserMedia
    let setPublisherHandler: SetPublisher
    let setPublisherAnswerHandler: SetPublisherAnswer
    let completedHandler: Completed

    private lazy var signalServer: SignalServer = makeSignalServer()
    private lazy var signalWSClient: WebSocketClient = makeSignalWSClient()

    private var state: State = .ready {
        didSet {
            log.debug("State transition: \(oldValue) → \(state)")
            switch state {
            case .ready:
                break
            case .preparing:
                prepare()
            case .sendJoinRequest:
                sendJoinRequest()
            case .joined:
                joined()
            case .setUpSubscriber:
                setUpSubscriber()
            case .publishLocalTracks:
                publishLocalTracks()
            case .restartICE:
                restartICE()
            case .waitingSubscriberOffer:
                // We are waiting for the event via WS
                break
            case .setPublisher:
                setPublisher()
            case .setPublisherAnswer:
                setPublisherAnswer()
            case .completed:
                completed()
            case .error(let message):
                log.error(message)
            }
        }
    }

    private let stages: [State] = [
        .ready,
        .preparing,
        .sendJoinRequest,
        .joined,
        .setUpSubscriber,
        .restartICE,
        .waitingSubscriberOffer,
        .setPublisher,
        .setPublisherAnswer,
        .publishLocalTracks,
        .completed
    ]

    private var publisherOffer: String!
    private var publisherAnswer: String!

    init(
        fromSFU: String,
        sessionID: String,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        publisher: PeerConnection,
        httpClient: HTTPClient,
        apiKey: String,
        eventNotificationCenter: EventNotificationCenter,
        environment: WebSocketClient.Environment,
        signalServerHostname: String,
        signalServerToken: String,
        signalWSClientConnectURL: String,
        connectOptions: ConnectOptions,
        audioTrack: RTCAudioTrack?,
        videoTrack: RTCVideoTrack?,
        sfu: SfuMiddleware,
        connectionStateDelegate: ConnectionStateDelegate,
        peerConnectionFactory: @escaping PeerConnectionFactory,
        joinRequestFactory: @escaping JoinRequestFactory,
        disconnectSignalChannel: @escaping DisconnectSignalChannel,
        pauseSubscriber: @escaping PauseSubscriber,
        updateSubscriber: @escaping UpdateSubscriber,
        setUpUserMedia: @escaping SetUpUserMedia,
        publishUserMedia: @escaping PublishUserMedia,
        setPublisher: @escaping SetPublisher,
        setPublisherAnswer: @escaping SetPublisherAnswer,
        completed: @escaping Completed
    ) {
        self.fromSFU = fromSFU
        self.sessionID = sessionID
        self.callSettings = callSettings
        self.audioSettings = audioSettings
        self.publisher = publisher
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.eventNotificationCenter = eventNotificationCenter
        self.environment = environment
        self.signalServerHostname = signalServerHostname
        self.signalServerToken = signalServerToken
        self.signalWSClientConnectURL = signalWSClientConnectURL
        self.connectOptions = connectOptions
        self.audioTrack = audioTrack
        self.videoTrack = videoTrack
        self.sfu = sfu
        self.connectionStateDelegate = connectionStateDelegate
        self.peerConnectionFactory = peerConnectionFactory
        self.joinRequestFactory = joinRequestFactory
        self.disconnectSignalChannel = disconnectSignalChannel
        self.pauseSubscriber = pauseSubscriber
        self.updateSubscriber = updateSubscriber
        self.setUpUserMedia = setUpUserMedia
        self.publishUserMedia = publishUserMedia
        self.setPublisherHandler = setPublisher
        self.setPublisherAnswerHandler = setPublisherAnswer
        self.completedHandler = completed

        eventNotificationCenter.add(middleware: self)
    }

    static func == (
        lhs: SessionMigrationAdapter,
        rhs: SessionMigrationAdapter
    ) -> Bool {
        lhs.identifier == rhs.identifier
    }

    func execute() { next() }

    // MARK: - State Handlers

    private func prepare() {
        _ = signalServer
        sfu.onSocketConnected = { Task { [weak self] in self?.next() } }
        signalWSClient.connect()
    }

    private func sendJoinRequest() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let peerConnection = try await peerConnectionFactory(.subscriber, signalServer)

                if let audioTrack {
                    peerConnection.addTrack(
                        audioTrack,
                        streamIds: ["temp-audio"],
                        trackType: .audio
                    )
                }

                if let videoTrack {
                    peerConnection.addTransceiver(
                        videoTrack,
                        streamIds: ["temp-video"],
                        direction: .recvOnly,
                        trackType: .video
                    )
                }
                let offer = try await peerConnection.createOffer()
                peerConnection.transceiver?.stopInternal()
                peerConnection.close()

                let payload = await joinRequestFactory(
                    offer.sdp,
                    signalServerToken,
                    fromSFU
                )

                var event = Stream_Video_Sfu_Event_SfuRequest()
                event.requestPayload = .joinRequest(payload)
                signalWSClient.engine?.send(message: event)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func joined() {
        disconnectSignalChannel(signalWSClient, signalServer)
        sfu.signalService = signalServer
        publisher.signalService = signalServer

        next()
    }

    private func setUpSubscriber() {
        Task {
            do {
                pauseSubscriber()
                let subscriber = try await peerConnectionFactory(.subscriber, signalServer)
                await updateSubscriber(subscriber)
                signalWSClient.engine?.send(message: Stream_Video_Sfu_Event_HealthCheckRequest())

                next()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func publishLocalTracks() {
        Task {
            guard callSettings.shouldPublish else {
                return
            }

            publisher.unpublishAllTracks()
            await setUpUserMedia()
            publishUserMedia()

            next()
        }
    }

    private func restartICE() {
        Task {
            do {
                publisher.onNegotiationNeeded = { _, _ in }

                let initialOffer = try await publisher.createOffer(constraints: .defaultConstraints)

                var updatedSdp = initialOffer.sdp
                if audioSettings.opusDtxEnabled {
                    updatedSdp = updatedSdp.replacingOccurrences(
                        of: "useinbandfec=1",
                        with: "useinbandfec=1;usedtx=1"
                    )
                }
                if audioSettings.redundantCodingEnabled {
                    updatedSdp = updatedSdp.preferredRedCodec
                }

                let offer = RTCSessionDescription(type: initialOffer.type, sdp: updatedSdp)
                try await publisher.setLocalDescription(offer)
                publisherOffer = offer.sdp

                next()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func setPublisher() {
        Task {
            do {
                publisherAnswer = try await setPublisherHandler(publisherOffer, signalWSClient, signalServer)

                next()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func setPublisherAnswer() {
        Task {
            do {
                try await setPublisherAnswerHandler(publisherAnswer, signalWSClient, signalServer)

                next()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func completed() {
        completedHandler()
        eventNotificationCenter.remove(middleware: self)
    }

    // MARK: - EventMiddleware

    func handle(event: WrappedEvent) -> WrappedEvent? {
        var message = "[SFU: \(sfu.signalService.hostname)]"
        switch event {
        case .internalEvent(let event):
            message += "Internal event: \(event.name)"
        case .coordinatorEvent(let videoEvent):
            message += "Coordinator event: \(videoEvent.name)"
        case .sfuEvent(let sfuEvent):
            message += "SFU event: \(sfuEvent)"
            switch sfuEvent {
            case .subscriberOffer:
                next()
            default:
                break
            }
        }
        log.debug(message)

        return event
    }

    // MARK: - Utilities

    private func makeSignalServer() -> Stream_Video_Sfu_Signal_SignalServer {
        .init(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: signalServerHostname,
            token: signalServerToken
        )
    }

    private func makeSignalWSClient() -> WebSocketClient {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false

        // Create a WebSocketClient.
        let webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .sfu,
            environment: environment,
            connectURL: .init(string: signalWSClientConnectURL)!,
            requiresAuth: false
        )

        webSocketClient.connectionStateDelegate = connectionStateDelegate

        webSocketClient.onWSConnectionEstablished = { [weak self] in self?.next() }

        return webSocketClient
    }

    private func next() {
        guard let currentIndex = stages.firstIndex(of: state) else {
            state = .error("Unable to transition from \(state)")
            return
        }

        let nextIndex = stages.index(after: currentIndex)

        state = nextIndex > stages.endIndex ? .ready : stages[nextIndex]
    }
}
