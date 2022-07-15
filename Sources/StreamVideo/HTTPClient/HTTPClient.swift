//
//  HTTPClient.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 15.7.22.
//

import Foundation

protocol HTTPClient {
    
    func execute(request: URLRequest) async throws -> Data
    
}

class URLSessionClient: HTTPClient {
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func execute(request: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) {data, response, error in
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
