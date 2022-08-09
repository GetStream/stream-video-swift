//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void
public typealias TokenUpdater = (Token) -> Void

public class StreamVideo {
    
    // Temporarly storing user in memory.
    public var userInfo: UserInfo
    var token: Token {
        didSet {
            callCoordinatorService.update(userToken: token.rawValue)
        }
    }

    private let tokenProvider: TokenProvider
    private let videoConfig: VideoConfig
    
    // Change it to your local IP address.
    private let hostname = "http://192.168.0.132:26991"
    private let wsEndpoint = "ws://192.168.0.132:8989"
    
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient?
    
    private let callsMiddleware = CallsMiddleware()
    private var participantsMiddleware = ParticipantsMiddleware()
    private var callEventsMiddleware = CallEventsMiddleware()
    
    private var currentCallInfo = [String: String]()
    
    internal var currentRoom: VideoRoom?
    
    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = EventNotificationCenter()
        let middlewares: [EventMiddleware] = [
            callsMiddleware,
            participantsMiddleware,
            callEventsMiddleware
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
    
    var callCoordinatorService: Stream_Video_CallCoordinatorService
    
    private let apiKey: APIKey
    private let videoService = VideoService()
    private let latencyService: LatencyService
        
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
        callCoordinatorService = Stream_Video_CallCoordinatorService(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token.rawValue
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

    public func startCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions,
        participantIds: [String]
    ) async throws -> VideoRoom {
        let createCallResponse = try await createCall(
            callType: callType.name,
            callId: callId,
            participantIds: participantIds
        )
        
        return try await joinCall(
            callType: callType,
            callId: createCallResponse.call.id,
            videoOptions: videoOptions
        )
    }
    
    public func joinCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions
    ) async throws -> VideoRoom {
        let joinCallResponse = try await joinCall(
            callId: callId,
            type: callType.name
        )
        
        let latencyByEdge = await measureLatencies(for: joinCallResponse.edges)
        
        let edgeServer = try await selectEdgeServer(
            callId: callId,
            latencyByEdge: latencyByEdge
        )
        
        if !videoConfig.persitingSocketConnection {
            connectWebSocketClient()
        }
        
        updateCallInfo(
            callId: callId,
            callType: callType.name
        )
                        
        let room = try await videoService.connect(
            url: edgeServer.url,
            token: edgeServer.token,
            participants: joinCallResponse.callParticipants(),
            options: videoOptions
        )
        
        participantsMiddleware.room = room
        callEventsMiddleware.room = room
        currentRoom = room
        
        return room
    }

    public func leaveCall() {
        webSocketClient?.set(callInfo: [:])
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
    
    func sendEvent(type: Stream_Video_UserEventType) {
        Task {
            var eventRequest = Stream_Video_SendEventRequest()
            eventRequest.callID = currentCallInfo[WebSocketConstants.callId] ?? ""
            eventRequest.callType = currentCallInfo[WebSocketConstants.callType] ?? ""
            eventRequest.userID = userInfo.id
            eventRequest.eventType = type
            _ = try? await callCoordinatorService.sendEvent(sendEventRequest: eventRequest)
        }
    }
    
    private func connectWebSocketClient() {
        if let connectURL = URL(string: wsEndpoint) {
            webSocketClient = makeWebSocketClient(url: connectURL, apiKey: apiKey)
            webSocketClient?.connect()
        }
    }
    
    private func createCall(
        callType: String,
        callId: String,
        participantIds: [String]
    ) async throws -> Stream_Video_CreateCallResponse {
        var createCallRequest = Stream_Video_CreateCallRequest()
        createCallRequest.id = callId
        createCallRequest.type = callType
        createCallRequest.participantIds = participantIds
        let createCallResponse = try await callCoordinatorService.createCall(createCallRequest: createCallRequest)
        return createCallResponse
    }
    
    private func measureLatencies(
        for edges: [Stream_Video_Edge]
    ) async -> [String: Stream_Video_Latency] {
        await withTaskGroup(of: [String: Stream_Video_Latency].self) { group in
            var result: [String: Stream_Video_Latency] = [:]
            for edge in edges {
                group.addTask {
                    var latency = Stream_Video_Latency()
                    let value = await self.latencyService.measureLatency(for: edge, tries: 3)
                    latency.measurementsSeconds = value
                    return [edge.latencyURL: latency]
                }
            }
            
            for await latency in group {
                for (key, value) in latency {
                    result[key] = value
                }
            }
            
            log.debug("Reported latencies for edges: \(result)")
            
            return result
        }
    }
    
    private func joinCall(callId: String, type: String) async throws -> Stream_Video_JoinCallResponse {
        var joinCallRequest = Stream_Video_JoinCallRequest()
        joinCallRequest.id = callId
        joinCallRequest.type = type
        let joinCallResponse = try await callCoordinatorService.joinCall(joinCallRequest: joinCallRequest)
        return joinCallResponse
    }
    
    private func selectEdgeServer(
        callId: String,
        latencyByEdge: [String: Stream_Video_Latency]
    ) async throws -> (url: String, token: String) {
        var selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
        selectEdgeRequest.callID = callId
        selectEdgeRequest.latencyByEdge = latencyByEdge
        let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
        let url = "wss://\(response.edgeServer.url)"
        let token = response.token
        log.debug("Selected edge server \(url)")
        return (url: url, token: token)
    }
    
    private static func makeURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let urlSession = URLSession(configuration: config)
        return urlSession
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
            connectURL: url,
            apiKey: self.apiKey.apiKeyString,
            userInfo: userInfo,
            token: token.rawValue
        )
        
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
