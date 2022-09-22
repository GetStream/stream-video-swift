//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import WebRTC

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void
public typealias TokenUpdater = (Token) -> Void

public class StreamVideo {
    
    // Temporarly storing user in memory.
    public var userInfo: UserInfo
    var token: Token {
        didSet {
            callCoordinatorController.update(token: token)
        }
    }

    private let tokenProvider: TokenProvider
    
    // Change it to your local IP address.
    private let hostname = "http://192.168.0.132:26991/rpc"
    private let wsEndpoint = "ws://192.168.0.132:8989/rpc/stream.video.coordinator.client_v1_rpc.Websocket/Connect"
    
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient?
    
    private let callsMiddleware = CallsMiddleware()
    
    private var currentCallInfo = [String: String]()
    
    internal let videoConfig: VideoConfig
    
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
    private var monitor: InternetConnectionMonitor?

    var tokenRetryTimer: TimerControl?
    var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()
        
    private let apiKey: APIKey
    private let latencyService: LatencyService
    
    private var currentCallController: CallController?
    private let callCoordinatorController: CallCoordinatorController
        
    public init(
        apiKey: String,
        user: UserInfo,
        token: Token,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping TokenProvider
    ) {
        self.apiKey = APIKey(apiKey)
        userInfo = user
        self.token = token
        self.tokenProvider = tokenProvider
        self.videoConfig = videoConfig
        httpClient = URLSessionClient(
            urlSession: Self.makeURLSession(),
            tokenProvider: tokenProvider
        )
        callCoordinatorController = CallCoordinatorController(
            httpClient: httpClient,
            userInfo: user,
            coordinatorInfo: CoordinatorInfo(
                apiKey: apiKey,
                hostname: hostname,
                token: token.rawValue
            ),
            videoConfig: videoConfig
        )

        latencyService = LatencyService(httpClient: httpClient)
                
        httpClient.setTokenUpdater { [weak self] token in
            self?.token = token
        }
        StreamVideoProviderKey.currentValue = self
        
        if videoConfig.persitingSocketConnection {
            connectWebSocketClient()
        }
    }
    
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

    public func leaveCall() {
        webSocketClient?.set(callInfo: [:])
        currentCallController?.cleanUp()
        if videoConfig.persitingSocketConnection {
            return
        }
        webSocketClient?.disconnect {
            log.debug("Web socket connection closed")
        }
    }
        
    public func incomingCalls() -> AsyncStream<IncomingCall> {
        let incomingCalls = AsyncStream(IncomingCall.self) { [weak self] continuation in
            self?.callsMiddleware.onCallCreated = { incomingCall in
                continuation.yield(incomingCall)
            }
        }
        return incomingCalls
    }
    
    internal static func makeURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let urlSession = URLSession(configuration: config)
        return urlSession
    }
    
    private func connectWebSocketClient() {
        if let connectURL = URL(string: wsEndpoint) {
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
            connectURL: url
        )
        
        webSocketClient.onConnect = { [weak self] in
            guard let self = self else { return }
            var payload = Stream_Video_AuthPayload()
            payload.token = self.token.rawValue
            payload.apiKey = apiKey.apiKeyString
            
            var user = Stream_Video_CreateUserRequest()
            user.name = self.userInfo.name ?? self.userInfo.id
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
                
        connectionRecoveryHandler = DefaultConnectionRecoveryHandler(
            webSocketClient: webSocketClient,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: backgroundTaskSchedulerBuilder(),
            internetConnection: InternetConnection(monitor: internetMonitor),
            reconnectionStrategy: DefaultRetryStrategy(),
            reconnectionTimerType: DefaultTimer.self,
            keepConnectionAliveInBackground: true
        )
    }
    
    var internetMonitor: InternetConnectionMonitor {
        if let monitor = monitor {
            return monitor
        } else {
            return InternetConnection.Monitor()
        }
    }
    
    var backgroundTaskSchedulerBuilder: () -> BackgroundTaskScheduler? = {
        if Bundle.main.isAppExtension {
            // No background task scheduler exists for app extensions.
            return nil
        } else {
            #if os(iOS)
            return IOSBackgroundTaskScheduler()
            #else
            // No need for background schedulers on macOS, app continues running when inactive.
            return nil
            #endif
        }
    }
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
