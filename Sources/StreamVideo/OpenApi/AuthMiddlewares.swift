//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserAuth: @unchecked Sendable, DefaultAPIClientMiddleware {
            
    var tokenProvider: () -> String
    var connectionId: () async throws -> String

    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        let connectionId = try await connectionId()
        // Ringing needs a connected caller to receive acceptance events.
        if requiresConnectionId(request) {
            try Task.checkCancellation()
            guard !connectionId.isEmpty else {
                throw ClientError("Cannot ring a call without a connection id.")
            }
        }
        if !connectionId.isEmpty {
            modifiedRequest.queryParams.append(
                .init(name: "connection_id", value: connectionId)
            )
        }
        modifiedRequest.headers["Authorization"] = tokenProvider()
        modifiedRequest.headers["stream-auth-type"] = "jwt"
        return try await next(modifiedRequest)
    }

    private func requiresConnectionId(_ request: Request) -> Bool {
        let path = Array(request.url.pathComponents.dropFirst())
        guard path.count >= 4, path.prefix(2) == ["video", "call"] else {
            return false
        }
        if request.method == .get, path.count == 4 {
            return request.queryParams.contains { $0.name == "ring" && $0.value == "true" }
        }
        guard request.method == .post else { return false }
        if path.count == 5, path.last == "ring" { return true }
        guard path.count == 4 || (path.count == 5 && path.last == "join"),
              let body = request.body,
              let payload = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        else { return false }
        return payload["ring"] as? Bool == true
    }
}

struct AnonymousAuth: DefaultAPIClientMiddleware {
    
    var token: String
    
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        if !token.isEmpty {
            modifiedRequest.headers["Authorization"] = token
        }
        modifiedRequest.headers["stream-auth-type"] = "anonymous"
        return try await next(modifiedRequest)
    }
}

struct DefaultParams: DefaultAPIClientMiddleware {
    
    let apiKey: String
    
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        modifiedRequest.queryParams.append(.init(name: "api_key", value: apiKey))
        modifiedRequest.headers["X-Stream-Client"] = SystemEnvironment.xStreamClientHeader
        modifiedRequest.headers["x-client-request-id"] = UUID().uuidString
        return try await next(modifiedRequest)
    }
}
