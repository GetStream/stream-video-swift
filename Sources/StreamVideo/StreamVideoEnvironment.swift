//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo {
    struct Environment: Sendable {
        // Builds the coordinator signaling socket. Backed by
        // `StreamCore.WebSocketClient` via ``CoordinatorWebSocket``; the payload
        // provider supplies the auth (`WSAuthMessageRequest`) sent on connect.
        var webSocketClientBuilder: @Sendable (
            _ eventNotificationCenter: EventNotificationCenter,
            _ url: URL,
            _ connectPayloadProvider: @escaping () -> (any Codable)?
        ) -> CoordinatorWebSocketProtocol = {
            let config = URLSessionConfiguration.default
            config.waitsForConnectivity = false

            return CoordinatorWebSocket(
                url: $1,
                eventNotificationCenter: $0,
                sessionConfiguration: config,
                connectPayloadProvider: $2,
                // Resolved here (StreamCore-free) so the CallKit reconnection
                // policy keeps working without importing StreamCore at the DI site.
                hasActiveCall: { InjectedValues[\.callKitService].callCount > 0 }
            )
        }
        
        var callControllerBuilder: @Sendable (
            _ defaultAPI: DefaultAPI,
            _ user: User,
            _ callId: String,
            _ callType: String,
            _ apiKey: String,
            _ videoConfig: VideoConfig,
            _ initialCallSettings: CallSettings,
            _ cachedLocation: String?
        ) -> CallController = {
            CallController(
                defaultAPI: $0,
                user: $1,
                callId: $2,
                callType: $3,
                apiKey: $4,
                videoConfig: $5,
                initialCallSettings: $6,
                cachedLocation: $7
            )
        }
        
        var apiTransportBuilder: @Sendable (
            _ tokenProvider: @escaping UserTokenProvider
        ) -> DefaultAPITransport = {
            URLSessionTransport(
                urlSession: Self.makeURLSession(),
                tokenProvider: $0
            )
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
