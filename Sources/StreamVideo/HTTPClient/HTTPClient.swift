//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

protocol HTTPClient: Sendable {
    
    func execute(request: URLRequest) async throws -> Data
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater)
    
    func refreshToken() async throws -> UserToken
    
    func update(tokenProvider: @escaping UserTokenProvider)
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
                log.debug("Refreshing user token", subsystems: .httpRequests)
                let token = try await refreshToken()
                if let onTokenUpdate = onTokenUpdate {
                    onTokenUpdate(token)
                }
                let updated = update(request: request, with: token.rawValue)
                log.debug("Retrying failed request with new token", subsystems: .httpRequests)
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
                    log.error("Error executing request", subsystems: .httpRequests, error: error)
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if (response.statusCode == 401 || response.statusCode == 403) && !isRetry {
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        if let code = errorResponse?["code"] as? Int, ClosedRange.tokenInvalidErrorCodes ~= code {
                            log.debug("Access token expired", subsystems: .httpRequests)
                            continuation.resume(throwing: ClientError.InvalidToken())
                        } else {
                            let requestURLString = request.url?.absoluteString ?? ""
                            log.debug(
                                "Error executing request \(requestURLString) \(String(describing: errorResponse))",
                                subsystems: .httpRequests
                            )
                            continuation.resume(throwing: ClientError.NetworkError(response.description))
                        }
                        return
                    } else if response.statusCode >= 400 {
                        let requestURLString = request.url?.absoluteString ?? ""
                        let errorResponse = Self.errorResponse(from: data, response: response) as? [String: Any]
                        log.error(
                            "Error executing request \(requestURLString) \(String(describing: errorResponse))",
                            subsystems: .httpRequests
                        )
                        continuation.resume(throwing: ClientError.NetworkError(response.description))
                        return
                    }
                }
                guard let data = data else {
                    log.debug("Received empty response", subsystems: .httpRequests)
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
