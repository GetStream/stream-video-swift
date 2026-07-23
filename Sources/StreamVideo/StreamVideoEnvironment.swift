//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo {
    struct Environment: Sendable {
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
