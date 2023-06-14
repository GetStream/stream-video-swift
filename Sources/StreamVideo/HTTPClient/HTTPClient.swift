//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol HTTPClient: Sendable {
    
    func execute(request: URLRequest) async throws -> Data
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater)
    
    func refreshToken() async throws -> UserToken
    
    func update(tokenProvider: @escaping UserTokenProvider)
}

struct UserAuth: DefaultAPIClientMiddleware {
    let token: String

    func intercept(_ request: Request, next: (Request) async throws -> (Data, URLResponse)) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        modifiedRequest.queryParams.append(.init(name: "api_key", value: "hd8szvscpxvd"))
        modifiedRequest.headers["Authorization"] = token
        modifiedRequest.headers["stream-auth-type"] = "jwt"
        return try await next(modifiedRequest)
    }
}

final class URLSessionTransport: DefaultAPITransport, @unchecked Sendable {
    private let urlSession: URLSession
    private var tokenProvider: UserTokenProvider?
    private let updateQueue: DispatchQueue = .init(
        label: "io.getStream.video.URLSessionClient",
        qos: .userInitiated
    )
    private(set) var onTokenUpdate: UserTokenUpdater?

    init(
        urlSession: URLSession,
        tokenProvider: UserTokenProvider? = nil
    ) {
        self.urlSession = urlSession
        self.tokenProvider = tokenProvider
    }

    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {
        updateQueue.async { [weak self] in
            self?.onTokenUpdate = tokenUpdater
        }
    }
    
    func update(tokenProvider: @escaping UserTokenProvider) {
        updateQueue.async { [weak self] in
            self?.tokenProvider = tokenProvider
        }
    }

    func refreshToken() async throws -> UserToken {
        try await withCheckedThrowingContinuation { continuation in
            tokenProvider? { result in
                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func execute(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await execute(request: request, isRetry: false)
        } catch {
            if error is ClientError.InvalidToken && tokenProvider != nil {
                log.debug("Refreshing user token")
                let token = try await refreshToken()
                if let onTokenUpdate = onTokenUpdate {
                    onTokenUpdate(token)
                }
                let updated = update(request: request, with: token)
                log.debug("Retrying failed request with new token")
                return try await execute(request: updated, isRetry: true)
            } else {
                throw error
            }
        }
    }

    private func execute(request: URLRequest, isRetry: Bool) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if (response.statusCode == 401 || response.statusCode == 403) && !isRetry {
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        if let code = errorResponse?["code"] as? Int, ClosedRange.tokenInvalidErrorCodes ~= code {
                            log.debug("Access token expired")
                            continuation.resume(throwing: ClientError.InvalidToken())
                        } else {
                            let requestURLString = request.url?.absoluteString ?? ""
                            log.debug("Error executing request \(requestURLString) \(String(describing: errorResponse))")
                            continuation.resume(throwing: ClientError.NetworkError(response.description))
                        }
                        return
                    } else if response.statusCode >= 400 {
                        let requestURLString = request.url?.absoluteString ?? ""
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        log.debug("Error executing request \(requestURLString) \(String(describing: errorResponse))")
                        continuation.resume(throwing: ClientError.NetworkError(response.description))
                        return
                    }
                }
                guard let data = data, let response = response else {
                    log.debug("Received empty response")
                    continuation.resume(throwing: ClientError.NetworkError())
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    private func update(request: URLRequest, with token: String) -> URLRequest {
        var updated = request
        updated.setValue(token, forHTTPHeaderField: "authorization")
        return updated
    }
    
    private static func errorResponse(from data: Data?, response: HTTPURLResponse) -> Any {
        guard let data = data else {
            return response.description
        }
        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            return response.description
        }
    }

    func execute(request: Request) async throws -> (Data, URLResponse) {
        var clone = request
        clone.headers["Content-Type"] = "application/json"
        clone.headers["X-Stream-Client"] = "stream-video-swift"
        return try await execute(request: clone.urlRequest())
    }
}

final class URLSessionClient: HTTPClient, @unchecked Sendable {
    
    private let urlSession: URLSession
    private var tokenProvider: UserTokenProvider?
    private let updateQueue: DispatchQueue = .init(
        label: "io.getStream.video.URLSessionClient",
        qos: .userInitiated
    )
    private(set) var onTokenUpdate: UserTokenUpdater?
    
    init(
        urlSession: URLSession,
        tokenProvider: UserTokenProvider? = nil
    ) {
        self.urlSession = urlSession
        self.tokenProvider = tokenProvider
    }
    
    func execute(request: URLRequest) async throws -> Data {
        do {
            let data = try await execute(request: request, isRetry: false)
            return data
        } catch {
            if error is ClientError.InvalidToken && tokenProvider != nil {
                log.debug("Refreshing user token")
                let token = try await refreshToken()
                if let onTokenUpdate = onTokenUpdate {
                    onTokenUpdate(token)
                }
                let updated = update(request: request, with: token)
                log.debug("Retrying failed request with new token")
                return try await execute(request: updated, isRetry: true)
            } else {
                throw error
            }
        }
    }
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {
        updateQueue.async { [weak self] in
            self?.onTokenUpdate = tokenUpdater
        }
    }
    
    func update(tokenProvider: @escaping UserTokenProvider) {
        updateQueue.async { [weak self] in
            self?.tokenProvider = tokenProvider
        }
    }
    
    func refreshToken() async throws -> UserToken {
        try await withCheckedThrowingContinuation { continuation in
            tokenProvider? { result in
                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func execute(request: URLRequest, isRetry: Bool) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    log.debug("Error executing request \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if (response.statusCode == 401 || response.statusCode == 403) && !isRetry {
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        if let code = errorResponse?["code"] as? Int, ClosedRange.tokenInvalidErrorCodes ~= code {
                            log.debug("Access token expired")
                            continuation.resume(throwing: ClientError.InvalidToken())
                        } else {
                            let requestURLString = request.url?.absoluteString ?? ""
                            log.debug("Error executing request \(requestURLString) \(String(describing: errorResponse))")
                            continuation.resume(throwing: ClientError.NetworkError(response.description))
                        }
                        return
                    } else if response.statusCode >= 400 {
                        let requestURLString = request.url?.absoluteString ?? ""
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        log.debug("Error executing request \(requestURLString) \(String(describing: errorResponse))")
                        continuation.resume(throwing: ClientError.NetworkError(response.description))
                        return
                    }
                }
                guard let data = data else {
                    log.debug("Received empty response")
                    continuation.resume(throwing: ClientError.NetworkError())
                    return
                }
                
                continuation.resume(returning: data)
            }
            task.resume()
        }
    }
    
    private func update(request: URLRequest, with token: String) -> URLRequest {
        var updated = request
        updated.setValue(token, forHTTPHeaderField: "authorization")
        return updated
    }
    
    private static func errorResponse(from data: Data?, response: HTTPURLResponse) -> Any {
        guard let data = data else {
            return response.description
        }
        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            return response.description
        }
    }
}
