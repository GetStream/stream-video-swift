//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class SFUAdapter: ConnectionStateDelegate, EventMiddleware, @unchecked Sendable {

    let service: Stream_Video_Sfu_Signal_SignalServer
    let connectionSubject = PassthroughSubject<WebSocketConnectionState, Never>()
    let eventSubject = PassthroughSubject<Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload, Never>()

    var hostname: String { service.hostname }

    weak var localTracksAdapter: LocalTracksAdapter?

    let sessionId: String
    private let webSocketClient: WebSocketClient

    private let encoder = JSONEncoder()
    private let disposableBag = DisposableBag()

    private let preferredReconnectionStrategyQueue = UnfairQueue()
    private var _preferredReconnectionStrategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy = .fast
    private(set) var preferredReconnectionStrategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy {
        get { preferredReconnectionStrategyQueue.sync { _preferredReconnectionStrategy } }
        set { preferredReconnectionStrategyQueue.sync { _preferredReconnectionStrategy = newValue } }
    }

    init(
        sessionId: String,
        url: URL,
        service: Stream_Video_Sfu_Signal_SignalServer,
        eventNotificationCenter: EventNotificationCenter,
        environment: WebSocketClient.Environment
    ) {
        self.sessionId = sessionId

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false

        webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .sfu,
            environment: environment,
            connectURL: url,
            requiresAuth: false
        )
        self.service = service

        webSocketClient.connectionStateDelegate = self

        observeErrors()
    }

    deinit {
        webSocketClient.disconnect {}
    }

    // MARK: - WebSocket

    func connect() {
        webSocketClient.connect()
    }

    func disconnect() {
        webSocketClient.disconnect {}
    }

    func join(
        sessionId: String,
        subscriberSessionDescription: String,
        isFastReconnecting: Bool,
        token: String
    ) {
        var payload = Stream_Video_Sfu_Event_JoinRequest()
        payload.clientDetails = SystemEnvironment.clientDetails
        payload.sessionID = sessionId
        payload.subscriberSdp = subscriberSessionDescription
        payload.fastReconnect = isFastReconnecting
        payload.token = token

        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .joinRequest(payload)

        webSocketClient.engine?.send(message: event)
    }

    func migrate(
        sessionId: String,
        subscriberSessionDescription: String,
        token: String,
        migratingFrom: String
    ) {
        var payload = Stream_Video_Sfu_Event_JoinRequest()
        payload.clientDetails = SystemEnvironment.clientDetails
        payload.sessionID = sessionId
        payload.subscriberSdp = subscriberSessionDescription
        payload.fastReconnect = false
        payload.token = token

        var migration = Stream_Video_Sfu_Event_Migration()
        migration.fromSfuID = migratingFrom
        // TODO: Get tracks
        //        migration.announcedTracks = loadTracks()
        //        migration.subscriptions = await loadTrackSubscriptionDetails()
        payload.migration = migration

        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .joinRequest(payload)

        webSocketClient.engine?.send(message: event)
    }

    func notifyLeave(
        sessionId: String,
        reason: String
    ) {
        var payload = Stream_Video_Sfu_Event_LeaveCallRequest()
        payload.sessionID = sessionId
        payload.reason = reason

        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .leaveCallRequest(payload)

        webSocketClient.engine?.send(message: event)
    }

    // MARK: ConnectionStateDelegate

    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        connectionSubject.send(state)
    }

    // MARK: - EventMiddleware

    func handle(
        event: WrappedEvent
    ) -> WrappedEvent? {
        guard case let .sfuEvent(sfuEvent) = event else {
            return event
        }
        eventSubject.send(sfuEvent)
        return event
    }

    // MARK: - SFU Service

    func iceTrickle(
        _ candidate: RTCIceCandidate,
        peerType: PeerConnectionType
    ) async throws {
        let json = try encoder.encode(ICECandidate(from: candidate))

        guard
            let jsonString = String(data: json, encoding: .utf8),
            !jsonString.isEmpty
        else {
            log.debug("Unable to trickle: \(candidate).")
            return
        }

        var iceTrickle = Stream_Video_Sfu_Models_ICETrickle()
        iceTrickle.iceCandidate = jsonString
        iceTrickle.sessionID = sessionId
        iceTrickle.peerType = peerType == .publisher
            ? .publisherUnspecified
            : .subscriber

        try Task.checkCancellation()
        _ = try await service.iceTrickle(iCETrickle: iceTrickle)
    }

    func setPublisher(
        _ sdp: String,
        tracks: [Stream_Video_Sfu_Models_TrackInfo]
    ) async throws -> RTCSessionDescription {
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = sdp
        request.sessionID = sessionId
        request.tracks = tracks

        let response = try await service.setPublisher(setPublisherRequest: request)
        return .init(type: .answer, sdp: response.sdp)
    }

    // MARK: - Private Helpers

    private func observeErrors() {
        eventSubject
            .compactMap {
                switch $0 {
                case let .error(error):
                    return error
                default:
                    return nil
                }
            }
            .sink { [weak self] error in
                guard let self else { return }
                self.preferredReconnectionStrategy = error.reconnectStrategy
            }
            .store(in: disposableBag)
    }
}
