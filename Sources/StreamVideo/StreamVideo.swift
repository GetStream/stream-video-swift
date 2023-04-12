//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import WebRTC

public typealias UserTokenProvider = (@escaping (Result<UserToken, Error>) -> Void) -> Void
public typealias UserTokenUpdater = (UserToken) -> Void

/// Main class for interacting with the `StreamVideo` SDK.
/// Needs to be initalized with a valid api key, user and token (and token provider).
public class StreamVideo {
    
    public let user: User
    public let videoConfig: VideoConfig
    
    var token: UserToken {
        didSet {
            callCoordinatorController.update(token: token)
        }
    }

    private let tokenProvider: UserTokenProvider
    private let endpointConfig: EndpointConfig = .production
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient? {
        didSet {
            setupConnectionRecoveryHandler()
        }
    }
    
    private let callsMiddleware = CallsMiddleware()
    private let permissionsMiddleware = PermissionsMiddleware()
    private let customEventsMiddleware = CustomEventsMiddleware()
    private let recordingEventsMiddleware = RecordingEventsMiddleware()
    private let allEventsMiddleware = AllEventsMiddleware()
        
    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = EventNotificationCenter()
        var middlewares: [EventMiddleware] = [
            callsMiddleware,
            permissionsMiddleware,
            customEventsMiddleware,
            recordingEventsMiddleware
        ]
        if videoConfig.listenToAllEvents {
            middlewares.append(allEventsMiddleware)
        }
        center.add(middlewares: middlewares)
        return center
    }()
    
    /// Background worker that takes care about client connection recovery when the Internet comes back OR app transitions from background to foreground.
    private(set) var connectionRecoveryHandler: ConnectionRecoveryHandler?
    private(set) var userConnectionProvider: UserConnectionProvider?
    private(set) var timerType: Timer.Type = DefaultTimer.self

    var tokenRetryTimer: TimerControl?
    var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()
        
    private let apiKey: APIKey
    private let latencyService: LatencyService
    
    private let callCoordinatorController: CallCoordinatorController
    private let environment: Environment
    
    /// Initializes a new instance of `StreamVideo` with the specified parameters.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The `User` who is logged in.
    ///   - token: The `UserToken` used to authenticate the user.
    ///   - videoConfig: A `VideoConfig` instance representing the current video config.
    ///   - tokenProvider: A closure that refreshes a token when it expires.
    /// - Returns: A new instance of `StreamVideo`.
    public convenience init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider
    ) {
        self.init(
            apiKey: apiKey,
            user: user,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: tokenProvider,
            environment: Environment()
        )
    }
        
    init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider,
        environment: Environment
    ) {
        self.apiKey = APIKey(apiKey)
        self.user = user
        self.token = token
        self.tokenProvider = tokenProvider
        self.videoConfig = videoConfig
        self.environment = environment
        httpClient = environment.httpClientBuilder(tokenProvider)
        callCoordinatorController = environment.callCoordinatorControllerBuilder(
            httpClient,
            user,
            apiKey,
            endpointConfig.hostname,
            token, videoConfig
        )
        latencyService = environment.latencyServiceBuilder(httpClient)
                
        httpClient.setTokenUpdater { [weak self] token in
            self?.token = token
        }
        StreamVideoProviderKey.currentValue = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallEnded),
            name: Notification.Name(CallNotification.callEnded),
            object: nil
        )
    }
    
    /// Connects the current user.
    public func connect() async throws {
        try await connectWebSocketClient()
    }
    
    public func makeCall(
        callType: CallType,
        callId: String,
        members: [User] = []
    ) -> Call {
        let callController = makeCallController(callType: callType, callId: callId)
        let recordingController = makeRecordingController(with: callController)
        let eventsController = makeEventsController()
        let permissionsController = makePermissionsController()
        return Call(
            callId: callId,
            callType: callType,
            callController: callController,
            recordingController: recordingController,
            eventsController: eventsController,
            permissionsController: permissionsController,
            members: members,
            videoOptions: VideoOptions(),
            allEventsMiddleWare: videoConfig.listenToAllEvents ? allEventsMiddleware : nil
        )
    }
    
    /// Creates a call controller used for voip notifications.
    /// - Returns: `VoipNotificationsController`
    public func makeVoipNotificationsController() -> VoipNotificationsController {
        callCoordinatorController.makeVoipNotificationsController()
    }
    
    /// Accepts the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func acceptCall(callId: String, callType: CallType) async throws {
        try await callCoordinatorController.sendEvent(
            type: .callAccepted,
            callId: callId,
            callType: callType
        )
    }
    
    /// Rejects the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func rejectCall(callId: String, callType: CallType) async throws {
        try await callCoordinatorController.sendEvent(
            type: .callRejected,
            callId: callId,
            callType: callType
        )
    }
        
    /// Async stream that reports all call events (incoming, rejected, canceled calls etc).
    public func callEvents() -> AsyncStream<CallEvent> {
        AsyncStream(CallEvent.self) { [weak self] continuation in
            self?.callsMiddleware.onCallEvent = { callEvent in
                continuation.yield(callEvent)
            }
        }
    }
    
    /// Disconnects the current `StreamVideo` client.
    public func disconnect() async {
        await withCheckedContinuation { continuation in
            webSocketClient?.disconnect {
                continuation.resume(returning: ())
            }
        }
    }
    
    // MARK: - private
    
    /// Creates a permissions controller used for managing permissions.
    /// - Returns: `PermissionsController`
    private func makePermissionsController() -> PermissionsController {
        let controller = PermissionsController(
            callCoordinatorController: callCoordinatorController,
            currentUser: user
        )
        permissionsMiddleware.onPermissionRequestEvent = { request in
            controller.onPermissionRequestEvent?(request)
        }
        permissionsMiddleware.onPermissionsUpdatedEvent = { request in
            controller.onPermissionsUpdatedEvent?(request)
        }
        return controller
    }
    
    /// Creates recording controller used for managing recordings.
    /// - Returns: `RecordingController`
    private func makeRecordingController(with callController: CallController) -> RecordingController {
        let controller = RecordingController(
            callCoordinatorController: callCoordinatorController,
            currentUser: user
        )
        controller.onRecordingRequestedEvent = { event in
            callController.updateCall(from: event)
        }
        recordingEventsMiddleware.onRecordingEvent = { event in
            controller.onRecordingEvent?(event)
            callController.updateCall(from: event)
        }
        return controller
    }
    
    /// Creates an events controller used for managing events.
    /// - Returns: `EventsController`
    private func makeEventsController() -> EventsController {
        let controller = EventsController(
            callCoordinatorController: callCoordinatorController,
            currentUser: user
        )
        customEventsMiddleware.onCustomEvent = { event in
            controller.onCustomEvent?(event)
        }
        customEventsMiddleware.onNewReaction = { event in
            controller.onNewReaction?(event)
        }
        return controller
    }
    
    /// Creates a call controller, used for establishing and managing a call.
    /// - Parameters:
    ///    - callType: the type of the call.
    ///    - callId: the id of the call.
    /// - Returns: `CallController`
    private func makeCallController(callType: CallType, callId: String) -> CallController {
        let controller = environment.callControllerBuilder(
            callCoordinatorController,
            user,
            callId,
            callType,
            apiKey.apiKeyString,
            videoConfig,
            videoConfig.listenToAllEvents ? allEventsMiddleware : nil
        )
        callsMiddleware.onCallUpdated = controller.update(callInfo:)
        return controller
    }
    
    private func connectWebSocketClient() async throws {
        let queryParams = endpointConfig.connectQueryParams(apiKey: apiKey.apiKeyString)
        if let connectURL = try? URL(string: endpointConfig.wsEndpoint)?.appendingQueryItems(queryParams) {
            webSocketClient = makeWebSocketClient(url: connectURL, apiKey: apiKey)
            webSocketClient?.connect()
        } else {
            throw ClientError.Unknown()
        }
        var connected = false
        var timeout = false
        let control = DefaultTimer.schedule(timeInterval: 30, queue: .sdk) {
            timeout = true
        }
        log.debug("Listening for WS connection")
        webSocketClient?.onConnected = {
            control.cancel()
            connected = true
            log.debug("WS connected")
        }

        while (!connected && !timeout) {
            try await Task.sleep(nanoseconds: 100_000)
        }
        
        if timeout {
            log.debug("Timeout while waiting for WS connection opening")
            throw ClientError.NetworkError()
        }
    }
    
    private func makeWebSocketClient(url: URL, apiKey: APIKey) -> WebSocketClient {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        
        // Create a WebSocketClient.
        let webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: JsonEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .coordinator,
            connectURL: url
        )
        
        webSocketClient.connectionStateDelegate = self
        webSocketClient.onWSConnectionEstablished = { [weak self] in
            guard let self = self else { return }
            
            let connectUserRequest = ConnectUserDetailsRequest(
                custom: RawJSON.convert(extraData: self.user.extraData),
                id: self.user.id,
                image: self.user.imageURL?.absoluteString,
                name: self.user.name
            )
            let authRequest = WSAuthMessageRequest(
                token: self.token.rawValue,
                userDetails: connectUserRequest
            )

            webSocketClient.engine?.send(jsonMessage: authRequest)
        }
        
        return webSocketClient
    }
    
    private func setupConnectionRecoveryHandler() {
        guard let webSocketClient = webSocketClient else {
            return
        }

        connectionRecoveryHandler = nil
        connectionRecoveryHandler = environment.connectionRecoveryHandlerBuilder(
            webSocketClient,
            eventNotificationCenter
        )
    }
    
    @objc private func handleCallEnded() {
        recordingEventsMiddleware.onRecordingEvent = nil
        callsMiddleware.onCallUpdated = nil
        customEventsMiddleware.onCustomEvent = nil
        customEventsMiddleware.onNewReaction = nil
        permissionsMiddleware.onPermissionRequestEvent = nil
        permissionsMiddleware.onPermissionsUpdatedEvent = nil
    }
}

extension StreamVideo: ConnectionStateDelegate {
    
    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        switch state {
        case let .disconnected(source):
            if let serverError = source.serverError, serverError.isInvalidTokenError {
                Task {
                    do {
                        self.token = try await httpClient.refreshToken()
                        log.debug("user token updated, will reconnect ws")
                        webSocketClient?.connect()
                    } catch {
                        log.error("Error refreshing token, will disconnect ws connection")
                    }
                }
            }
        case let .connected(healthCheckInfo: healtCheckInfo):
            if let healthCheck = healtCheckInfo.coordinatorHealthCheck {
                callCoordinatorController.update(connectionId: healthCheck.connectionId)
            }
        default:
            log.debug("Web socket connection state update \(state)")
        }
    }
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
