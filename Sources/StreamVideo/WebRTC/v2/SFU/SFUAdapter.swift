//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A class that manages the communication with a Selective Forwarding Unit (SFU) for video streaming.
///
/// The `SFUAdapter` class handles both WebSocket connections and HTTP requests to the SFU server.
/// It provides methods for managing video tracks, updating subscriptions, and handling WebRTC signaling.
final class SFUAdapter: ConnectionStateDelegate, CustomStringConvertible, @unchecked Sendable {

    /// Configuration for the SFU service.
    struct ServiceConfiguration {
        /// The URL of the SFU service.
        var url: URL
        /// The API key for authentication.
        var apiKey: String
        /// The authentication token.
        var token: String
        /// The HTTP client used for network requests. Defaults to a URLSession-based client.
        var httpClient: HTTPClient = URLSessionClient(
            urlSession: StreamVideo.Environment.makeURLSession()
        )
    }

    /// Configuration for the WebSocket connection.
    struct WebSocketConfiguration {
        /// The URL for the WebSocket connection.
        var url: URL
        /// The event notification center for handling WebSocket events.
        var eventNotificationCenter: EventNotificationCenter
        /// The session configuration for the WebSocket connection. Defaults to not waiting for connectivity.
        var sessionConfiguration: URLSessionConfiguration = .default.toggleWaitsForConnectivity(false)
        /// The decoder for WebRTC events. Defaults to a standard WebRTCEventDecoder.
        var eventDecoder: WebRTCEventDecoder = WebRTCEventDecoder()
    }

    private let processingQueue = DispatchQueue(label: "io.getstream.sfu.event.processingQueue")
    private let signalService: SFUSignalService
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let webSocketFactory: WebSocketClientProviding
    private var webSocket: WebSocketClient
    private var disposableBag = DisposableBag()
    private var requestDisposableBag = DisposableBag()
    private var isConnected: Bool {
        switch connectionState {
        case .connected, .authenticating:
            return true
        default:
            return false
        }
    }

    /// The current connection state of the WebSocket.
    @Published private(set) var connectionState: WebSocketConnectionState = .initialized

    /// A publisher that is used to inform subscribers that the SFUAdapter has refreshed its webSocket
    /// connection.
    var refreshPublisher: AnyPublisher<Void, Never> { refreshSubject.eraseToAnyPublisher() }

    /// The URL used for the WebSocket connection.
    var connectURL: URL { webSocket.connectURL }
    /// The hostname of the SFU service.
    var hostname: String { signalService.hostname }

    // MARK: - CustomStringConvertible

    var description: String {
        """
        Address: \(Unmanaged.passUnretained(webSocket).toOpaque())
        SFUAdapter is delegate: \(webSocket.connectionStateDelegate === self)
        ConnectionState: \(connectionState)
        ConnectURL: \(connectURL)
        Hostname: \(hostname)
        """
    }

    /// Initializes a new SFUAdapter instance.
    ///
    /// - Parameters:
    ///   - serviceConfiguration: The configuration for the SFU service.
    ///   - webSocketConfiguration: The configuration for the WebSocket connection.
    convenience init(
        serviceConfiguration: ServiceConfiguration,
        webSocketConfiguration: WebSocketConfiguration
    ) {
        let webSocketFactory = WebSocketClientFactory()
        self.init(
            signalService: .init(
                httpClient: serviceConfiguration.httpClient,
                apiKey: serviceConfiguration.apiKey,
                hostname: serviceConfiguration.url.absoluteString,
                token: serviceConfiguration.token
            ),
            webSocket: webSocketFactory.build(
                sessionConfiguration: webSocketConfiguration.sessionConfiguration,
                eventDecoder: webSocketConfiguration.eventDecoder,
                eventNotificationCenter: webSocketConfiguration.eventNotificationCenter,
                webSocketClientType: .sfu,
                connectURL: webSocketConfiguration.url,
                requiresAuth: false
            ),
            webSocketFactory: webSocketFactory
        )
    }

    init(
        signalService: SFUSignalService,
        webSocket: WebSocketClient,
        webSocketFactory: WebSocketClientProviding
    ) {
        self.signalService = signalService
        self.webSocket = webSocket
        self.webSocketFactory = webSocketFactory

        webSocket.connectionStateDelegate = self

        setUpPublishers()
    }

    deinit {
        disposableBag.removeAll()
        requestDisposableBag.removeAll()
        webSocket.disconnect {}
    }

    // MARK: - WebSocket

    /// Returns a publisher that will be triggered every time the specified event type is being received.
    ///
    /// - Parameters:
    ///   - eventType: The event type to listen for
    ///   - file: The file from which we are requesting the publisher. Used for logging.
    ///   - function: The function from which we are requesting the publisher. Used for logging.
    ///   - line: The line from which we are requesting the publisher. Used for logging.
    func publisher<T>(
        eventType: T.Type,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> AnyPublisher<T, Never> {
        webSocket
            .eventSubject
            .compactMap {
                switch $0 {
                case let .sfuEvent(event):
                    return event.payload(T.self)
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Initiates a connection to the WebSocket server.
    func connect() {
        log.debug("Will connect \(self)", subsystems: .sfu)
        webSocket.connect()
    }

    /// Disconnects from the WebSocket server and clears all disposables.
    ///
    /// - Note: the disconnection will send the `.userInitiated` DisconnectionSource.
    func disconnect() async {
        guard isConnected else { return }
        log.debug("Will disconnect \(self)", subsystems: .sfu)
        requestDisposableBag.removeAll()
        await webSocket.disconnect()
    }

    /// Sends a health check request to the WebSocket server.
    func sendHealthCheck() {
        webSocket
            .engine?
            .send(message: Stream_Video_Sfu_Event_HealthCheckRequest())
    }

    /// Sends a message through the WebSocket connection.
    ///
    /// - Parameter message: The message to be sent, conforming to the SendableEvent protocol.
    func send(message: SendableEvent) {
        statusCheck()
        log.debug(message, subsystems: .sfu)
        webSocket.engine?.send(message: message)
    }

    /// Refreshes the WebSocket connection with a new configuration.
    ///
    /// This method disconnects the current WebSocket, clears all disposables,
    /// and creates a new WebSocket connection with the provided configuration.
    ///
    /// - Parameter webSocketConfiguration: The new configuration for the WebSocket connection.
    func refresh(
        webSocketConfiguration: WebSocketConfiguration
    ) {
        log.debug("Will refresh \(self).", subsystems: .sfu)
        webSocket.connectionStateDelegate = nil
        webSocket.disconnect(code: .init(rawValue: 4002)!) {}
        requestDisposableBag.removeAll()
        webSocket = webSocketFactory.build(
            sessionConfiguration: webSocketConfiguration.sessionConfiguration,
            eventDecoder: webSocketConfiguration.eventDecoder,
            eventNotificationCenter: webSocketConfiguration.eventNotificationCenter,
            webSocketClientType: .sfu,
            environment: .init(),
            connectURL: webSocketConfiguration.url,
            requiresAuth: false
        )
        webSocket.connectionStateDelegate = self

        refreshSubject.send(())

        log.debug("Did refresh \(self).", subsystems: .sfu)
    }

    func sendJoinRequest(
        _ payload: Stream_Video_Sfu_Event_JoinRequest
    ) {
        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .joinRequest(payload)
        send(message: event)
    }

    func sendLeaveRequest(
        reason: String = "",
        for sessionId: String
    ) {
        statusCheck()
        var payload = Stream_Video_Sfu_Event_LeaveCallRequest()
        payload.sessionID = sessionId
        payload.reason = reason

        var event = Stream_Video_Sfu_Event_SfuRequest()
        event.requestPayload = .leaveCallRequest(payload)

        webSocket.engine?.send(message: event)
    }

    // MARK: - Service

    /// Updates the mute state of a specific track.
    ///
    /// This method sends a request to the SFU server to update the mute state of a specified track.
    /// It uses a retry policy to handle potential network issues.
    ///
    /// - Parameters:
    ///   - trackType: The type of track to update (e.g., audio, video).
    ///   - isMuted: A boolean indicating whether the track should be muted.
    ///   - sessionId: The ID of the current session.
    ///   - retryPolicy: The retry policy to use for the request. Defaults to `.fastAndSimple`.
    /// - Throws: An error if the update fails after retries.
    func updateTrackMuteState(
        _ trackType: Stream_Video_Sfu_Models_TrackType,
        isMuted: Bool,
        for sessionId: String,
        retryPolicy: RetryPolicy = .fastAndSimple
    ) async throws {
        statusCheck()
        var muteState = Stream_Video_Sfu_Signal_TrackMuteState()
        muteState.trackType = trackType
        muteState.muted = isMuted

        var request = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        request.muteStates = [muteState]
        request.sessionID = sessionId

        signalService.subject.send(request)

        let task = Task { [request, signalService, retryPolicy] in
            try await executeTask(retryPolicy: retryPolicy) {
                try Task.checkCancellation()
                return try await signalService.updateMuteStates(updateMuteStatesRequest: request)
            }
        }
        task.store(in: requestDisposableBag)
        let response = try await task.value
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
        signalService.subject.send(response)
    }

    /// Sends call statistics to the SFU server.
    ///
    /// This method collects various statistics about the call and sends them to the SFU server.
    /// If no report is provided, the method returns without doing anything.
    ///
    /// - Parameters:
    ///   - report: An optional CallStatsReport containing the statistics to send.
    ///   - sessionId: The ID of the current session.
    /// - Throws: An error if sending the stats fails.
    func sendStats(
        _ report: CallStatsReport?,
        for sessionId: String
    ) async throws {
        statusCheck()
        guard let report else { return }
        var statsRequest = Stream_Video_Sfu_Signal_SendStatsRequest()
        statsRequest.sessionID = sessionId
        statsRequest.sdk = "stream-ios"
        statsRequest.sdkVersion = SystemEnvironment.version
        statsRequest.webrtcVersion = SystemEnvironment.webRTCVersion
        statsRequest.publisherStats = report.publisherRawStats?.jsonString ?? ""
        statsRequest.subscriberStats = report.subscriberRawStats?.jsonString ?? ""
        let task = Task { [statsRequest, signalService] in
            try Task.checkCancellation()
            return try await signalService.sendStats(sendStatsRequest: statsRequest)
        }
        task.store(in: requestDisposableBag)
        let response = try await task.value
        signalService.subject.send(response)
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
    }

    /// Toggles noise cancellation for the current session.
    ///
    /// This method enables or disables noise cancellation by sending the appropriate request to the SFU server.
    /// It uses different request types based on whether noise cancellation is being enabled or disabled.
    ///
    /// - Parameters:
    ///   - isEnabled: A boolean indicating whether noise cancellation should be enabled (true) or disabled (false).
    ///   - sessionId: The ID of the current session.
    /// - Throws: An error if the request to start or stop noise cancellation fails.
    func toggleNoiseCancellation(
        _ isEnabled: Bool,
        for sessionId: String
    ) async throws {
        statusCheck()
        if isEnabled {
            var request = Stream_Video_Sfu_Signal_StartNoiseCancellationRequest()
            request.sessionID = sessionId
            let task = Task { [request, signalService] in
                try Task.checkCancellation()
                return try await signalService.startNoiseCancellation(
                    startNoiseCancellationRequest: request
                )
            }
            task.store(in: requestDisposableBag)
            let response = try await task.value
            signalService.subject.send(response)
        } else {
            var request = Stream_Video_Sfu_Signal_StopNoiseCancellationRequest()
            request.sessionID = sessionId
            let task = Task { [request, signalService] in
                try Task.checkCancellation()
                return try await signalService.stopNoiseCancellation(
                    stopNoiseCancellationRequest: request
                )
            }
            task.store(in: requestDisposableBag)
            let response = try await task.value
            signalService.subject.send(response)
            if response.error.code != .unspecified && !response.error.message.isEmpty {
                throw response.error
            }
        }
    }

    /// Sets up the publisher for the current session.
    ///
    /// This method sends a request to the SFU server to set up a publisher with the provided session
    /// description and track information.
    /// It's typically used when initializing or updating the video stream configuration.
    ///
    /// - Parameters:
    ///   - sessionDescription: The Session Description Protocol (SDP) string for the publisher.
    ///   - tracks: An array of TrackInfo objects describing the tracks to be published.
    ///   - sessionId: The ID of the current session.
    /// - Returns: A SetPublisherResponse from the SFU server, which  contains additional
    /// information about the publisher setup.
    /// - Throws: An error if the request to set the publisher fails.
    func setPublisher(
        sessionDescription: String,
        tracks: [Stream_Video_Sfu_Models_TrackInfo],
        for sessionId: String
    ) async throws -> Stream_Video_Sfu_Signal_SetPublisherResponse {
        var request = Stream_Video_Sfu_Signal_SetPublisherRequest()
        request.sdp = sessionDescription
        request.sessionID = sessionId
        request.tracks = tracks
        let task = Task { [request, signalService] in
            try await executeTask(retryPolicy: .fastCheckValue { true }) { [weak self] in
                try Task.checkCancellation()
                guard self?.isConnected == true else {
                    throw ClientError("Not connected.")
                }
                return try await signalService.setPublisher(setPublisherRequest: request)
            }
        }
        log.debug(request, subsystems: .sfu)
        task.store(in: requestDisposableBag)
        let response = try await task.value
        signalService.subject.send(response)
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
        return response
    }

    /// Updates the subscriptions for tracks in the current session.
    ///
    /// This method sends a request to the SFU server to update which tracks the client is subscribed to.
    /// It uses a persistent retry policy to ensure the update is successful.
    ///
    /// - Parameters:
    ///   - tracks: An array of TrackSubscriptionDetails, specifying which tracks to subscribe to or
    ///   unsubscribe from.
    ///   - sessionId: The ID of the current session.
    /// - Throws: An error if the subscription update fails after all retry attempts.
    /// - Note: This method uses a retry policy named ".neverGonnaGiveYouUp", which  will persistently
    /// retry until successful.
    func updateSubscriptions(
        tracks: [Stream_Video_Sfu_Signal_TrackSubscriptionDetails],
        for sessionId: String
    ) async throws {
        statusCheck()
        var request = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        request.sessionID = sessionId
        request.tracks = tracks

        try Task.checkCancellation()

        let task = Task { [request, signalService] in
            try Task.checkCancellation()
            return try await executeTask(retryPolicy: .neverGonnaGiveYouUp { true }) {
                try Task.checkCancellation()
                return try await signalService.updateSubscriptions(updateSubscriptionsRequest: request)
            }
        }
        task.store(in: requestDisposableBag)
        let response = try await task.value
        signalService.subject.send(response)
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
    }

    /// Sends an SDP answer to the SFU server as part of the WebRTC negotiation process.
    ///
    /// This method is typically called in response to receiving an offer from the SFU server.
    /// It sends the local session description as an answer back to the server.
    ///
    /// - Parameters:
    ///   - sessionDescription: The SDP (Session Description Protocol) answer string.
    ///   - peerType: The type of peer sending the answer (e.g., publisher or subscriber).
    ///   - sessionId: The ID of the current session.
    /// - Throws: An error if sending the answer fails after retry attempts.
    /// - Note: This method uses a retry policy named ".fastCheckValue", which  will quickly retry a few
    /// times before giving up.
    func sendAnswer(
        sessionDescription: String,
        peerType: Stream_Video_Sfu_Models_PeerType,
        for sessionId: String
    ) async throws {
        var request = Stream_Video_Sfu_Signal_SendAnswerRequest()
        request.sessionID = sessionId
        request.peerType = peerType
        request.sdp = sessionDescription
        let task = Task { [request, signalService] in
            try await executeTask(retryPolicy: .fastCheckValue { true }) {
                try Task.checkCancellation()
                return try await signalService.sendAnswer(sendAnswerRequest: request)
            }
        }
        task.store(in: requestDisposableBag)
        let response = try await task.value
        signalService.subject.send(response)
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
    }

    /// Sends an ICE candidate to the SFU server using the ICE trickle technique.
    ///
    /// ICE trickle is an optimization of the ICE (Interactive Connectivity Establishment) protocol
    /// that allows the incremental exchange of ICE candidates as they become available. This method
    /// is typically called multiple times during the WebRTC connection setup process, each time a new
    /// ICE candidate is discovered.
    ///
    /// - Parameters:
    ///   - candidate: A string representation of the ICE candidate.
    ///   - peerType: The type of peer (e.g., publisher or subscriber) that discovered this ICE candidate.
    ///   - sessionId: The ID of the current session.
    /// - Throws: An error if sending the ICE candidate fails.
    func iCETrickle(
        candidate: String,
        peerType: Stream_Video_Sfu_Models_PeerType,
        for sessionId: String
    ) async throws {
        log.debug(
            "Will trickle for peerType:\(peerType) on sessionId:\(sessionId)",
            subsystems: .sfu
        )
        var request = Stream_Video_Sfu_Models_ICETrickle()
        request.iceCandidate = candidate
        request.sessionID = sessionId
        request.peerType = peerType
        let task = Task { [request, signalService] in
            try Task.checkCancellation()
            return try await signalService.iceTrickle(iCETrickle: request)
        }
        task.store(in: requestDisposableBag)
        let response = try await task.value
        signalService.subject.send(response)
        if response.error.code != .unspecified && !response.error.message.isEmpty {
            throw response.error
        }
    }

    // MARK: - ConnectionStateDelegate

    /// Updates the connection state of the SFUAdapter when the WebSocket connection state changes.
    ///
    /// This method is part of the `ConnectionStateDelegate` protocol implementation. It's called
    /// by the WebSocketClient whenever the connection state changes, allowing the SFUAdapter
    /// to keep track of the current WebSocket connection state.
    ///
    /// - Parameters:
    ///   - client: The WebSocketClient that triggered the state update.
    ///   - state: The new WebSocketConnectionState.
    ///
    /// - Note: This method updates the `connectionState` property of the SFUAdapter,
    ///         which is a published property that observers can react to.
    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        log.debug(
            """
            WebSocket connectionState changed to \(state)
            client: \(Unmanaged.passUnretained(client).toOpaque())
            """,
            subsystems: .sfu
        )
        connectionState = state
    }

    // MARK: - Private helpers

    private func setUpPublishers() {
        disposableBag.removeAll()

        refreshPublisher
            .log(.debug, subsystems: .sfu) { "SFUAdapter refreshed its webSocket connection." }
            .sink { [weak self] in self?.setUpPublishers() }
            .store(in: disposableBag)

        webSocket
            .eventSubject
            .log(.debug, subsystems: .sfu) {
                """
                SFU received event
                \($0)
                """
            }
            .sink { _ in }
            .store(in: disposableBag)

        signalService
            .subject
            .log(.debug, subsystems: .sfu)
            .sink { _ in }
            .store(in: disposableBag)
    }

    private func statusCheck(
        functionName: StaticString = #function,
        filename: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        guard !isConnected else { return }
        log.assert(
            false,
            """
            Attempting to send a message before connecting to SFU
            hostname: \(hostname)
            """,
            subsystems: .sfu,
            functionName: functionName,
            fileName: filename,
            lineNumber: lineNumber
        )
    }
}
