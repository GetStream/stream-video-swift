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
    private static let endpointConfig: EndpointConfig = .production
    private let httpClient: HTTPClient
    
    private var webSocketClient: WebSocketClient? {
        didSet {
            setupConnectionRecoveryHandler()
        }
    }
        
    private let eventsMiddleware = WSEventsMiddleware()
    private var continuations = [AsyncStream<Event>.Continuation]()
            
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
    private let callCoordinatorController: CallCoordinatorController
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
    
    /// Initializes a new instance of `StreamVideo` with the specified parameters.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The `User` who is logged in.
    ///   - token: The `UserToken` used to authenticate the user.
    ///   - videoConfig: A `VideoConfig` instance representing the current video config.
    ///   - pushNotificationsConfig: Config for push notifications.
    /// - Returns: A new instance of `StreamVideo`.
    public convenience init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        pushNotificationsConfig: PushNotificationsConfig = .default
    ) {
        let tokenProvider: UserTokenProvider = { result in
            log.error("Provide a token provider, since the token has expiry date")
            result(
                .failure(ClientError.MissingToken())
            )
        }
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
    
    /// Initializes a new instance of `StreamVideo` as a guest user, with the specified parameters.
    /// This method is async and throwing, since it loads a guest token first.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The guest user.
    ///   - videoConfig: A `VideoConfig` instance representing the current video config.
    ///   - pushNotificationsConfig: Config for push notifications.
    /// - Returns: A new instance of `StreamVideo`.
    public convenience init(
        apiKey: String,
        user: User,
        videoConfig: VideoConfig = VideoConfig(),
        pushNotificationsConfig: PushNotificationsConfig = .default
    ) async throws {
        try await self.init(
            apiKey: apiKey,
            user: user,
            videoConfig: videoConfig,
            pushNotificationsConfig: pushNotificationsConfig,
            environment: Environment()
        )
    }
    
    convenience init(
        apiKey: String,
        user: User,
        videoConfig: VideoConfig = VideoConfig(),
        pushNotificationsConfig: PushNotificationsConfig = .default,
        environment: Environment
    ) async throws {
        var tokenProvider: UserTokenProvider = { _ in }
        
        // Create the call coordinator to fetch a guest token.
        let httpClient = environment.httpClientBuilder(tokenProvider)
        let callCoordinatorController = environment.callCoordinatorControllerBuilder(
            httpClient,
            user,
            apiKey,
            Self.endpointConfig.hostname,
            "",
            videoConfig
        )
        
        // Fetch the guest token.
        let guestUserResponse = try await callCoordinatorController.createGuestUser(with: user.id)
        let token = UserToken(rawValue: guestUserResponse.accessToken)
        callCoordinatorController.update(token: token)
        
        // Update the user and token provider.
        let updatedUser = guestUserResponse.user.toUser
        callCoordinatorController.update(user: updatedUser)
        tokenProvider = { result in
            Self.loadGuestToken(
                userId: user.id,
                callCoordinatorController: callCoordinatorController,
                result: result
            )
        }
        httpClient.update(tokenProvider: tokenProvider)
        
        self.init(
            apiKey: apiKey,
            user: updatedUser,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: tokenProvider,
            httpClient: httpClient,
            callCoordinatorController: callCoordinatorController,
            pushNotificationsConfig: pushNotificationsConfig,
            environment: environment
        )
    }
        
    init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider,
        httpClient: HTTPClient? = nil,
        callCoordinatorController: CallCoordinatorController? = nil,
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
        self.httpClient = httpClient ?? environment.httpClientBuilder(tokenProvider)
        self.callCoordinatorController = callCoordinatorController ?? environment.callCoordinatorControllerBuilder(
            self.httpClient,
            user,
            apiKey,
            Self.endpointConfig.hostname,
            token.rawValue,
            videoConfig
        )
        self.httpClient.setTokenUpdater { [weak self] token in
            self?.token = token
        }
        StreamVideoProviderKey.currentValue = self
    }
    
    /// Connects the current user.
    public func connect() async throws {
        if case .connected(healthCheckInfo: _) = webSocketClient?.connectionState {
            return
        }
        if user.type == .anonymous {
            // Anonymous users can't connect to the WS.
            throw ClientError.MissingPermissions()
        }
        try await connectWebSocketClient()
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
            callCoordinatorController: callCoordinatorController,
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
            coordinatorClient: self.callCoordinatorController.coordinatorClient,
            callsQuery: callsQuery
        )
        return controller
    }
    
    /// Sets a device for push notifications.
    /// - Parameter id: the id of the device (token) for push notifications.
    public func setDevice(id: String) async throws {
        try await setDevice(
            id: id,
            pushProvider: pushNotificationsConfig.pushProviderInfo.pushProvider,
            name: pushNotificationsConfig.pushProviderInfo.name,
            isVoip: false
        )
    }
    
    /// Sets a device for VoIP push notifications.
    /// - Parameter id: the id of the device (token) for VoIP push notifications.
    public func setVoipDevice(id: String) async throws {
        try await setDevice(
            id: id,
            pushProvider: pushNotificationsConfig.voipPushProviderInfo.pushProvider,
            name: pushNotificationsConfig.voipPushProviderInfo.name,
            isVoip: true
        )
    }
    
    /// Deletes the device with the provided id.
    /// - Parameter id: the id of the device that will be deleted.
    public func deleteDevice(id: String) async throws {
        try await callCoordinatorController.coordinatorClient.deleteDevice(with: id)
    }
    
    /// Lists the devices registered for the user.
    /// - Returns: an array of `Device`s.
    public func listDevices() async throws -> [Device] {
        try await callCoordinatorController.coordinatorClient.listDevices().devices
    }
    
    /// Disconnects the current `StreamVideo` client.
    public func disconnect() async {
        for continuation in continuations {
            continuation.finish()
        }
        continuations.removeAll()
        await withCheckedContinuation { continuation in
            webSocketClient?.disconnect {
                continuation.resume(returning: ())
            }
        }
    }
    
    public func subscribe() -> AsyncStream<Event> {
        AsyncStream(Event.self) { [weak self] continuation in
            self?.continuations.append(continuation)
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
            callCoordinatorController,
            user,
            callId,
            callType,
            apiKey.apiKeyString,
            videoConfig
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
                custom: RawJSON.convert(customData: self.user.customData),
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
    
    private func setDevice(
        id: String,
        pushProvider: PushNotificationsProvider,
        name: String,
        isVoip: Bool
    ) async throws {
        let createDeviceRequest = CreateDeviceRequest(
            id: id,
            pushProvider: .init(rawValue: pushProvider.rawValue),
            pushProviderName: name,
            user: UserRequest(id: user.id),
            userId: user.id,
            voipToken: isVoip
        )
        
        log.debug("Sending request to save device")

        try await callCoordinatorController.coordinatorClient.createDevice(request: createDeviceRequest)
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
    
    private static func loadGuestToken(
        userId: String,
        callCoordinatorController: CallCoordinatorController,
        result: @escaping (Result<UserToken, Error>) -> Void
    )  {
        Task {
            do {
                let response = try await callCoordinatorController.createGuestUser(with: userId)
                let tokenValue = response.accessToken
                callCoordinatorController.update(user: response.user.toUser)
                let token = UserToken(rawValue: tokenValue)
                result(.success(token))
            } catch {
                result(.failure(error))
            }
        }
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
            for continuation in continuations {
                continuation.yield(WSDisconnected())
            }
        case let .connected(healthCheckInfo: healtCheckInfo):
            if let healthCheck = healtCheckInfo.coordinatorHealthCheck {
                callCoordinatorController.update(connectionId: healthCheck.connectionId)
            }
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
    }
    
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
