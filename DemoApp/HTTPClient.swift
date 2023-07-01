//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import Foundation

protocol HTTPClient: Sendable {
    
    func execute<T: Codable>(url: URL) async throws -> T
    
}

final class URLSessionClient: HTTPClient, @unchecked Sendable {
    
    private let urlSession = URLSession.shared
            
    func execute<T: Codable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let data = try await execute(request: request)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    }
    
    func execute(request: URLRequest) async throws -> Data {
        let data = try await execute(request: request, isRetry: false)
        return data
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
                    if response.statusCode == 403, !isRetry {
                        log.debug("Access token expired", subsystems: .httpRequests)
                        continuation.resume(throwing: ClientError.InvalidToken())
                        return
                    } else if response.statusCode >= 400 {
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
}
