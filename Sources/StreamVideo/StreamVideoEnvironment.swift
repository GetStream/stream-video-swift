//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo {
    struct Environment {
        var httpClientBuilder: (
            _ tokenProvider: @escaping UserTokenProvider
        ) -> HTTPClient = {
            URLSessionClient(
                urlSession: Self.makeURLSession(),
                tokenProvider: $0
            )
        }
        
        var callControllerBuilder: (
            _ callCoordinatorController: CallCoordinatorController,
            _ user: User,
            _ callId: String,
            _ callType: String,
            _ apiKey: String,
            _ videoConfig: VideoConfig
        ) -> CallController = {
            CallController(
                callCoordinatorController: $0,
                user: $1,
                callId: $2,
                callType: $3,
                apiKey: $4,
                videoConfig: $5
            )
        }
        
        var callCoordinatorControllerBuilder: (
            _ httpClient: HTTPClient,
            _ user: User,
            _ apiKey: String,
            _ hostname: String,
            _ token: String,
            _ videoConfig: VideoConfig
        ) -> CallCoordinatorController = {
            CallCoordinatorController(
                httpClient: $0,
                user: $1,
                coordinatorInfo: CoordinatorInfo(
                    apiKey: $2,
                    hostname: $3,
                    token: $4
                ),
                videoConfig: $5
            )
        }
        
        var connectionRecoveryHandlerBuilder: (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                backgroundTaskScheduler: backgroundTaskSchedulerBuilder(),
                internetConnection: InternetConnection(monitor: InternetConnection.Monitor()),
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: true
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
