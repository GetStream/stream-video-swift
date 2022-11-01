//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import WebRTC

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void
public typealias TokenUpdater = (Token) -> Void

/// Main class for interacting with the `StreamVideo` SDK.
/// Needs to be initalized with a valid api key, user and token (and token provider).
public class StreamVideo {
    
    // Temporarly storing user in memory.
    public var userInfo: UserInfo
    public let videoConfig: VideoConfig
    
    var token: Token {
        didSet {
            callCoordinatorController.update(token: token)
        }
    }

    private let tokenProvider: TokenProvider
    private let endpointConfig: EndpointConfig = .stagingConfig
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient? {
        didSet {
            setupConnectionRecoveryHandler()
        }
    }
    
    private let callsMiddleware = CallsMiddleware()
    
    private var currentCallInfo = [String: String]()
    
    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = EventNotificationCenter()
        let middlewares: [EventMiddleware] = [
            callsMiddleware
        ]
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
    
    public private(set) var currentCallController: CallController?
    private let callCoordinatorController: CallCoordinatorController
    private let environment: Environment
    
    public convenience init(
        apiKey: String,
        user: UserInfo,
        token: Token,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping TokenProvider
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
        user: UserInfo,
        token: Token,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping TokenProvider,
        environment: Environment
    ) {
        self.apiKey = APIKey(apiKey)
        userInfo = user
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
        
        if videoConfig.persitingSocketConnection {
            connectWebSocketClient()
        }
    }
    
    /// Creates a call controller, used for establishing and managing a call.
    /// - Parameters:
    ///    - callType: the type of the call.
    ///    - callId: the id of the call.
    /// - Returns: `CallController`
    public func makeCallController(callType: CallType, callId: String) -> CallController {
        let controller = CallController(
            callCoordinatorController: callCoordinatorController,
            userInfo: userInfo,
            callId: callId,
            callType: callType,
            apiKey: apiKey.apiKeyString,
            tokenProvider: tokenProvider
        )
        currentCallController = controller
        if !videoConfig.persitingSocketConnection {
            connectWebSocketClient()
        }
        return controller
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
            type: .acceptedCall,
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
            type: .rejectedCall,
            callId: callId,
            callType: callType
        )
    }
    
    /// Cancels the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func cancelCall(callId: String, callType: CallType) async throws {
        try await callCoordinatorController.sendEvent(
            type: .cancelledCall,
            callId: callId,
            callType: callType
        )
    }

    /// Leaves the current call. It clears all call-related state.
    public func leaveCall() {
        postNotification(with: CallNotification.callEnded)
        webSocketClient?.set(callInfo: [:])
        currentCallController?.cleanUp()
        currentCallController = nil
        if videoConfig.persitingSocketConnection {
            return
        }
        webSocketClient?.disconnect {
            log.debug("Web socket connection closed")
        }
    }
        
    /// Async stream that reports all call events (incoming, rejected, canceled calls etc).
    public func callEvents() -> AsyncStream<CallEvent> {
        let callEvents = AsyncStream(CallEvent.self) { [weak self] continuation in
            self?.callsMiddleware.onCallEvent = { callEvent in
                continuation.yield(callEvent)
            }
        }
        return callEvents
    }
    
    private func connectWebSocketClient() {
        if let connectURL = URL(string: endpointConfig.wsEndpoint) {
            webSocketClient = makeWebSocketClient(url: connectURL, apiKey: apiKey)
            webSocketClient?.connect()
        }
    }
    
    private func updateCallInfo(callId: String, callType: String) {
        currentCallInfo = [
            WebSocketConstants.callId: callId,
            WebSocketConstants.callType: callType
        ]
        webSocketClient?.set(callInfo: currentCallInfo)
    }
    
    private func makeWebSocketClient(url: URL, apiKey: APIKey) -> WebSocketClient {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        
        // Create a WebSocketClient.
        let webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: EventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .coordinator,
            connectURL: url
        )
        
        webSocketClient.onConnect = { [weak self] in
            guard let self = self else { return }
            var payload = Stream_Video_AuthPayload()
            payload.token = self.token.rawValue
            payload.apiKey = apiKey.apiKeyString
            
            var user = Stream_Video_CreateUserRequest()
            user.name = self.userInfo.name
            user.imageURL = self.userInfo.imageURL?.absoluteString ?? ""
            payload.user = user
            
            var event = Stream_Video_WebsocketClientEvent()
            event.event = .authRequest(payload)
            webSocketClient.engine?.send(message: event)
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
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
