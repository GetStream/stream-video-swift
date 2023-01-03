//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol HTTPClient: Sendable {

    func execute(request: URLRequest) async throws -> Data

    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater)

    func refreshToken() async throws -> UserToken
}

final class URLSessionClient: HTTPClient, @unchecked Sendable {

    private let urlSession: URLSession
    private let tokenProvider: UserTokenProvider
    private let updateQueue: DispatchQueue = .init(
        label: "io.getStream.video.URLSessionClient",
        qos: .userInitiated
    )
    private(set) var onTokenUpdate: UserTokenUpdater?

    init(
        urlSession: URLSession,
        tokenProvider: @escaping UserTokenProvider
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

    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {
        updateQueue.async { [weak self] in
            self?.onTokenUpdate = tokenUpdater
        }
    }

    func refreshToken() async throws -> UserToken {
        try await withCheckedThrowingContinuation { continuation in
            tokenProvider { result in
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
                    if response.statusCode == 403, !isRetry {
                        log.debug("Access token expired")
                        continuation.resume(throwing: ClientError.InvalidToken())
                        return
                    } else if response.statusCode >= 400 {
                        let requestURLString = request.url?.absoluteString ?? ""
                        let errorResponse = Self.errorResponse(from: data, response: response)
                        if let errorResponse = errorResponse as? [String: Any],
                           let meta = errorResponse["meta"] as? [String: Any],
                           let code = meta["code"] as? String,
                           code == "AUTH_TOKEN_EXPIRED", !isRetry {
                            // Temporary handling until the backend is ready.
                            log.debug("Access token expired")
                            continuation.resume(throwing: ClientError.InvalidToken())
                            return
                        }
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
