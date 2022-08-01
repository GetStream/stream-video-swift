//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

protocol HTTPClient {
    
    func execute(request: URLRequest) async throws -> Data
    
    func setTokenUpdater(_ tokenUpdater: @escaping TokenUpdater)
    
}

class URLSessionClient: HTTPClient {
    
    private let urlSession: URLSession
    private let tokenProvider: TokenProvider
    var onTokenUpdate: TokenUpdater?
    
    init(
        urlSession: URLSession,
        tokenProvider: @escaping TokenProvider
    ) {
        self.urlSession = urlSession
        self.tokenProvider = tokenProvider
    }
    
    func execute(request: URLRequest) async throws -> Data {
        do {
            let data = try await execute(request: request, isRetry: false)
            return data
        } catch {
            if error is ClientError.InvalidToken {
                log.debug("Refreshing user token")
                let token = try await refreshToken()
                if let onTokenUpdate = onTokenUpdate {
                    onTokenUpdate(token)
                }
                let updated = update(request: request, with: token.rawValue)
                log.debug("Retrying failed request with new token")
                return try await execute(request: updated, isRetry: true)
            } else {
                throw error
            }
        }
    }
    
    func setTokenUpdater(_ tokenUpdater: @escaping TokenUpdater) {
        self.onTokenUpdate = tokenUpdater
    }
    
    private func refreshToken() async throws -> Token {
        return try await withCheckedThrowingContinuation { continuation in
            tokenProvider { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func execute(request: URLRequest, isRetry: Bool) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) {data, response, error in
                if let error = error {
                    log.debug("Error executing request \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 403, !isRetry {
                        log.debug("Access token expired")
                        continuation.resume(throwing: ClientError.InvalidToken())
                        return
                    } else if response.statusCode >= 400 {
                        let requestURLString = request.url?.absoluteString ?? ""
                        let errorResponse = self.errorResponse(from: data, response: response)
                        log.debug("Error executing request \(requestURLString) \(errorResponse)")
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
    
    private func errorResponse(from data: Data?, response: HTTPURLResponse) -> Any {
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
