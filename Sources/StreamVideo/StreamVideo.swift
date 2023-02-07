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
    
    // Temporarly storing user in memory.
    public var user: User
    public let videoConfig: VideoConfig
    
    var token: UserToken {
        didSet {
            callCoordinatorController.update(token: token)
        }
    }

    private let tokenProvider: UserTokenProvider
    private let endpointConfig: EndpointConfig = .frankfurtStagingConfig
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient? {
        didSet {
            setupConnectionRecoveryHandler()
        }
    }
    
    private let callsMiddleware = CallsMiddleware()
        
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
            user: user,
            callId: callId,
            callType: callType,
            apiKey: apiKey.apiKeyString,
            videoConfig: videoConfig,
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
    
    /// Cancels the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func cancelCall(callId: String, callType: CallType) async throws {
        try await callCoordinatorController.sendEvent(
            type: .callCancelled,
            callId: callId,
            callType: callType
        )
    }

    /// Leaves the current call. It clears all call-related state.
    public func leaveCall() {
        postNotification(with: CallNotification.callEnded)
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
        AsyncStream(CallEvent.self) { [weak self] continuation in
            self?.callsMiddleware.onCallEvent = { callEvent in
                continuation.yield(callEvent)
            }
        }
    }
    
    /// Disconnects the current `StreamVideo` client.
    public func disconnect() async {
        await withCheckedContinuation { continuation in
            currentCallController?.cleanUp()
            currentCallController = nil
            webSocketClient?.disconnect {
                continuation.resume(returning: ())
            }
        }
    }
    
    private func connectWebSocketClient() {
        let urlString =
            "\(endpointConfig.wsEndpoint)?api_key=\(apiKey.apiKeyString)&stream-auth-type=jwt&X-Stream-Client=stream-video-swift"
        if let connectURL = URL(string: urlString) {
            webSocketClient = makeWebSocketClient(url: connectURL, apiKey: apiKey)
            webSocketClient?.connect()
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
        webSocketClient.onConnect = { [weak self] in
            guard let self = self else { return }
            let userDetails = UserDetailsPayload(
                id: self.user.id,
                name: self.user.name,
                username: self.user.id,
                role: "member" // TODO:
            )
            let connectRequest = ConnectRequest(
                token: self.token.rawValue,
                user_details: userDetails
            )
            
            /*
              //TODO: when it's ready.
             let userObject = UserObjectRequest(id: self.user.id)
             let deviceFieldsRequest = DeviceFieldsRequest() //TODO: add stuff
             let authRequest = VideoWSAuthMessageRequest(
                 device: deviceFieldsRequest,
                 token: self.token.rawValue,
                 userDetails: userObject
             )
              */
            
            webSocketClient.engine?.send(jsonMessage: connectRequest)
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

extension StreamVideo: ConnectionStateDelegate {
    
    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        switch state {
        case let .disconnected(source):
            // TODO: check for token-related error code.
            if source.serverError != nil {
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
                callCoordinatorController.update(connectionId: healthCheck.connection_id)
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
