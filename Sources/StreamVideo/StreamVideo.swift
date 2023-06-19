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
public class StreamVideo: ObservableObject {

    typealias EventHandling = ((Event) -> ())?

    @Published public var connectionStatus: ConnectionStatus = .initialized
    
    public private(set) var user: User
    public let videoConfig: VideoConfig
    
    var token: UserToken

    private var tokenProvider: UserTokenProvider
    private static let endpointConfig: EndpointConfig = .production
    // TODO: rename this into coordinatorClient
    private let defaultAPI: DefaultAPI
    private let apiTransport: DefaultAPITransport
    
    private var webSocketClient: WebSocketClient? {
        didSet {
            setupConnectionRecoveryHandler()
        }
    }
        
    private let eventsMiddleware = WSEventsMiddleware()
    private var continuations = [AsyncStream<Event>.Continuation]()
    private var cachedLocation: String?
    private var connectTask: Task<Void, Error>?
    private var eventHandlers = [EventHandling]()
            
    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = EventNotificationCenter()
        eventsMiddleware.add(subscriber: self)
        var middlewares: [EventMiddleware] = [
            eventsMiddleware
        ]
        center.add(middlewares: middlewares)
        return center
    }()
    
    /// Background worker that takes care about client connection recovery when the Internet comes back OR app transitions from background to foreground.
    private(set) var connectionRecoveryHandler: ConnectionRecoveryHandler?
    private(set) var timerType: Timer.Type = DefaultTimer.self

    var tokenRetryTimer: TimerControl?
    var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()
        
    private let apiKey: APIKey
    private let environment: Environment
    private let pushNotificationsConfig: PushNotificationsConfig
    
    /// Initializes a new instance of `StreamVideo` with the specified parameters.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The `User` who is logged in.
    ///   - token: The `UserToken` used to authenticate the user.
    ///   - videoConfig: A `VideoConfig` instance representing the current video config.
    ///   - pushNotificationsConfig: Config for push notifications.
    ///   - tokenProvider: A closure that refreshes a token when it expires.
    /// - Returns: A new instance of `StreamVideo`.
    public convenience init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        pushNotificationsConfig: PushNotificationsConfig = .default,
        tokenProvider: @escaping UserTokenProvider
    ) {
        self.init(
            apiKey: apiKey,
            user: user,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: tokenProvider,
            pushNotificationsConfig: pushNotificationsConfig,
            environment: Environment()
        )
    }    
        
    init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider,
        pushNotificationsConfig: PushNotificationsConfig,
        environment: Environment
    ) {
        self.apiKey = APIKey(apiKey)
        self.user = user
        self.token = token
        self.tokenProvider = tokenProvider
        self.videoConfig = videoConfig
        self.environment = environment
        self.pushNotificationsConfig = pushNotificationsConfig
        
        self.apiTransport = environment.apiTransportBuilder(tokenProvider)
        let defaultParams = DefaultParams(apiKey: apiKey)
        self.defaultAPI = DefaultAPI(
            basePath: Self.endpointConfig.baseVideoURL,
            transport: apiTransport,
            middlewares: [defaultParams]
        )
        StreamVideoProviderKey.currentValue = self
        (self.apiTransport as? URLSessionTransport)?.setTokenUpdater { [weak self] userToken in
            self?.token = userToken
        }
        if user.type != .anonymous {
            let userAuth = UserAuth { [unowned self] in
                self.token.rawValue
            } connectionId: { [unowned self] in
                await self.loadConnectionId()
            }
            defaultAPI.middlewares.append(userAuth)
        } else {
            let anonymousAuth = AnonymousAuth(token: token.rawValue)
            defaultAPI.middlewares.append(anonymousAuth)
        }
        self.prefetchLocation()
        connectTask = Task {
            if user.type == .guest {
                do {
                    let guestInfo = try await loadGuestUserInfo(for: user, apiKey: apiKey)
                    self.user = guestInfo.user
                    self.token = guestInfo.token
                    self.tokenProvider = guestInfo.tokenProvider
                    try await self.connectUser(isInitial: true)
                } catch {
                    log.error("Error connecting as guest \(error.localizedDescription)")
                }
            } else {
                try await self.connectUser(isInitial: true)
            }
        }
    }
    
    /// Connects the current user.
    public func connect() async throws {
        try await connectUser()
    }
    
    /// Creates a call with the provided call id, type and members.
    /// This doesn't method create the call on the backend, for that you need to call `join` or `getOrCreateCall`.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the all.
    /// - Returns: `Call` object.
    public func call(
        callType: String,
        callId: String
    ) -> Call {
        let callController = makeCallController(callType: callType, callId: callId)
        let call = Call(
            callType: callType,
            callId: callId,
            defaultAPI: defaultAPI,
            callController: callController,
            videoOptions: VideoOptions()
        )
        eventsMiddleware.add(subscriber: call)
        return call
    }

    /// Creates a controller used for querying and watching calls.
    /// - Parameter callsQuery: the query for the calls.
    /// - Returns: `CallsController`
    public func makeCallsController(callsQuery: CallsQuery) -> CallsController {
        let controller = CallsController(
            streamVideo: self,
            defaultAPI: defaultAPI,
            callsQuery: callsQuery
        )
        return controller
    }
    
    /// Sets a device for push notifications.
    /// - Parameter id: the id of the device (token) for push notifications.
    @discardableResult
    public func setDevice(id: String) async throws -> ModelResponse {
        try await setDevice(
            id: id,
            pushProvider: pushNotificationsConfig.pushProviderInfo.pushProvider,
            name: pushNotificationsConfig.pushProviderInfo.name,
            isVoip: false
        )
    }
    
    /// Sets a device for VoIP push notifications.
    /// - Parameter id: the id of the device (token) for VoIP push notifications.
    @discardableResult
    public func setVoipDevice(id: String) async throws -> ModelResponse {
        try await setDevice(
            id: id,
            pushProvider: pushNotificationsConfig.voipPushProviderInfo.pushProvider,
            name: pushNotificationsConfig.voipPushProviderInfo.name,
            isVoip: true
        )
    }
    
    /// Deletes the device with the provided id.
    /// - Parameter id: the id of the device that will be deleted.
    @discardableResult
    public func deleteDevice(id: String) async throws -> ModelResponse {
        try await defaultAPI.deleteDevice(id: id, userId: user.id)
    }
    
    /// Lists the devices registered for the user.
    /// - Returns: an array of `Device`s.
    public func listDevices() async throws -> [Device] {
        try await defaultAPI.listDevices().devices
    }
    
    /// Disconnects the current `StreamVideo` client.
    public func disconnect() async {
        continuations.forEach { $0.finish() }
        continuations.removeAll()
        eventHandlers.removeAll()

        await withCheckedContinuation { [webSocketClient] continuation in
            if let webSocketClient = webSocketClient {
                webSocketClient.disconnect {
                    continuation.resume()
                }
            } else {
                continuation.resume()
            }
        }
    }
    
    public func subscribe() -> AsyncStream<Event> {
        AsyncStream(Event.self) { [weak self] continuation in
            self?.continuations.append(continuation)
        }
    }

    public func subscribe<WSEvent: Event>(for event: WSEvent.Type) -> AsyncStream<WSEvent> {
        return AsyncStream(event) { [weak self] continuation in
            let eventHandler: EventHandling = { event in
                if let event = event as? WSEvent {
                    continuation.yield(event)
                }
            }
            self?.eventHandlers.append(eventHandler)
        }
    }

    // MARK: - private
    
    /// Creates a call controller, used for establishing and managing a call.
    /// - Parameters:
    ///    - callType: the type of the call.
    ///    - callId: the id of the call.
    /// - Returns: `CallController`
    private func makeCallController(callType: String, callId: String) -> CallController {
        let controller = environment.callControllerBuilder(
            defaultAPI,
            user,
            callId,
            callType,
            apiKey.apiKeyString,
            videoConfig,
            cachedLocation
        )
        return controller
    }
    
    private func connectWebSocketClient() async throws {
        let queryParams = Self.endpointConfig.connectQueryParams(apiKey: apiKey.apiKeyString)
        if let connectURL = try? URL(string: Self.endpointConfig.wsEndpoint)?.appendingQueryItems(queryParams) {
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
        let webSocketClient = environment.webSocketClientBuilder(eventNotificationCenter, url)
        
        webSocketClient.connectionStateDelegate = self
        webSocketClient.onWSConnectionEstablished = { [weak self] in
            guard let self = self else { return }
            
            let connectUserRequest = ConnectUserDetailsRequest(
                custom: self.user.customData,
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
    
    private func loadConnectionId() async -> String {
        if let connectionId = loadConnectionIdFromHealthcheck() {
            return connectionId
        }
        
        guard webSocketClient?.connectionState == .connecting
                || webSocketClient?.connectionState == .authenticating else {
            return ""
        }
        
        var timeout = false
        let control = DefaultTimer.schedule(timeInterval: 5, queue: .sdk) {
            timeout = true
        }
        log.debug("Waiting for connection id")

        while (loadConnectionIdFromHealthcheck() == nil && !timeout) {
            try? await Task.sleep(nanoseconds: 100_000)
        }
        
        control.cancel()
        
        if let connectionId = loadConnectionIdFromHealthcheck() {
            log.debug("Connection id available from the WS")
            return connectionId
        }
        
        return ""
    }
    
    private func loadConnectionIdFromHealthcheck() -> String? {
        if case let .connected(healthCheckInfo: healtCheckInfo) = webSocketClient?.connectionState {
            if let healthCheck = healtCheckInfo.coordinatorHealthCheck {
                return healthCheck.connectionId
            }
        }
        return nil
    }
    
    private func loadGuestUserInfo(
        for user: User,
        apiKey: String
    ) async throws -> (user: User, token: UserToken, tokenProvider: UserTokenProvider) {
        let guestUserResponse = try await Self.createGuestUser(
            id: user.id,
            apiKey: apiKey,
            environment: environment
        )
        let token = UserToken(rawValue: guestUserResponse.accessToken)
        
        // Update the user and token provider.
        let updatedUser = guestUserResponse.user.toUser
        let tokenProvider = { [environment = self.environment] result in
            Self.loadGuestToken(
                userId: user.id,
                apiKey: apiKey,
                environment: environment,
                result: result
            )
        }
        return (user: updatedUser, token: token, tokenProvider: tokenProvider)
    }
    
    private func setDevice(
        id: String,
        pushProvider: PushNotificationsProvider,
        name: String,
        isVoip: Bool
    ) async throws -> ModelResponse {
        let createDeviceRequest = CreateDeviceRequest(
            id: id,
            pushProvider: .init(rawValue: pushProvider.rawValue),
            pushProviderName: name,
            user: UserRequest(id: user.id),
            userId: user.id,
            voipToken: isVoip
        )
        
        log.debug("Sending request to save device")

        return try await defaultAPI.createDevice(createDeviceRequest: createDeviceRequest)
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
    
    private func connectUser(isInitial: Bool = false) async throws {
        if !isInitial && connectTask != nil {
            log.debug("Waiting for already running connect task")
            _ = await connectTask?.result
        }
        if case .connected(healthCheckInfo: _) = webSocketClient?.connectionState {
            return
        }
        if user.type == .anonymous {
            // Anonymous users can't connect to the WS.
            throw ClientError.MissingPermissions()
        }
        try await connectWebSocketClient()
    }
    
    private static func createGuestUser(
        id: String,
        apiKey: String,
        environment: Environment
    ) async throws -> CreateGuestResponse {
        let transport = environment.apiTransportBuilder { _ in }
        let defaultAPI = DefaultAPI(
            basePath: Self.endpointConfig.baseVideoURL,
            transport: transport,
            middlewares: [DefaultParams(apiKey: apiKey), AnonymousAuth(token: "")]
        )
        let request = CreateGuestRequest(user: UserRequest(id: id))
        return try await defaultAPI.createGuest(createGuestRequest: request)
    }
    
    private static func loadGuestToken(
        userId: String,
        apiKey: String,
        environment: Environment,
        result: @escaping (Result<UserToken, Error>) -> Void
    )  {
        Task {
            do {
                let response = try await createGuestUser(
                    id: userId,
                    apiKey: apiKey,
                    environment: environment
                )
                let tokenValue = response.accessToken
                let token = UserToken(rawValue: tokenValue)
                result(.success(token))
            } catch {
                result(.failure(error))
            }
        }
    }
    
    private func prefetchLocation() {
        Task {
            self.cachedLocation = try await LocationFetcher.getLocation()
        }
    }
    
}

extension StreamVideo: ConnectionStateDelegate {
    
    func webSocketClient(
        _ client: WebSocketClient,
        didUpdateConnectionState state: WebSocketConnectionState
    ) {
        self.connectionStatus = ConnectionStatus(webSocketConnectionState: state)
        switch state {
        case let .disconnected(source):
            if let serverError = source.serverError, serverError.isInvalidTokenError {
                Task {
                    do {
                        guard let apiTransport = apiTransport as? URLSessionTransport else { return }
                        self.token = try await apiTransport.refreshToken()
                        log.debug("user token updated, will reconnect ws")
                        webSocketClient?.connect()
                    } catch {
                        log.error("Error refreshing token, will disconnect ws connection")
                    }
                }
            }
            for continuation in continuations {
                continuation.yield(WSDisconnected())
            }
        case .connected(healthCheckInfo: _):
            for continuation in continuations {
                continuation.yield(WSConnected())
            }
        default:
            log.debug("Web socket connection state update \(state)")
        }
    }
}

extension StreamVideo: WSEventsSubscriber {
    
    func onEvent(_ event: Event) {
        for continuation in continuations {
            continuation.yield(event)
        }

        for eventHandler in eventHandlers {
            eventHandler?(event)
        }
    }
    
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
