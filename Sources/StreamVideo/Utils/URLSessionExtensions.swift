//
//  URLSessionExtensions.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 15.7.22.
//

import Foundation

extension URLSession {
    
    func execute(request: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) {data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data else {
                    //TODO: errors
                    continuation.resume(throwing: NSError(domain: "stream", code: 123))
                    return
                }
                
                continuation.resume(returning: data)
            }
            task.resume()
        }
    }
    
}
