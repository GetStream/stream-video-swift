//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo {
    struct Environment {
        var webSocketClientBuilder: (
            _ eventNotificationCenter: EventNotificationCenter,
            _ url: URL
        ) -> WebSocketClient = {
            let config = URLSessionConfiguration.default
            config.waitsForConnectivity = false
            
            // Create a WebSocketClient.
            let webSocketClient = WebSocketClient(
                sessionConfiguration: config,
                eventDecoder: JsonEventDecoder(),
                eventNotificationCenter: $0,
                webSocketClientType: .coordinator,
                connectURL: $1
            )
            
            return webSocketClient
        }
        
        var callControllerBuilder: (
            _ defaultAPI: DefaultAPI,
            _ user: User,
            _ callId: String,
            _ callType: String,
            _ apiKey: String,
            _ videoConfig: VideoConfig,
            _ cachedLocation: String?
        ) -> CallController = {
            CallController(
                defaultAPI: $0,
                user: $1,
                callId: $2,
                callType: $3,
                apiKey: $4,
                videoConfig: $5,
                cachedLocation: $6
            )
        }
        
        var apiTransportBuilder: (
            _ tokenProvider: @escaping UserTokenProvider
        ) -> DefaultAPITransport = {
            URLSessionTransport(
                urlSession: Self.makeURLSession(),
                tokenProvider: $0
            )
        }
        
        var connectionRecoveryHandlerBuilder: (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ refreshTokenHandler: @escaping () async throws -> Void
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                backgroundTaskScheduler: backgroundTaskSchedulerBuilder(),
                internetConnection: InternetConnection(monitor: InternetConnection.Monitor()),
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: true,
                refreshTokenHandler: $2
            )
        }
        
        private static var backgroundTaskSchedulerBuilder: () -> BackgroundTaskScheduler? = {
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
        
        internal static func makeURLSession() -> URLSession {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            let urlSession = URLSession(configuration: config)
            return urlSession
        }
    }
}
