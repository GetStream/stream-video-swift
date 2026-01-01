//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class HTTPClient_Mock: @unchecked Sendable, HTTPClient, DefaultAPITransport {
            
    var dataResponses = [Data]()
    var errors = [Error]()
    var requestCounter = 0
    
    func execute(request: URLRequest) async throws -> Data {
        requestCounter += 1
        if !errors.isEmpty {
            let error = errors.removeFirst()
            throw error
        }
        if dataResponses.isEmpty {
            throw ClientError.Unexpected("Please setup responses")
        }
        return dataResponses.removeFirst()
    }
    
    func execute(request: Request) async throws -> (Data, URLResponse) {
        requestCounter += 1
        if dataResponses.isEmpty {
            throw ClientError.Unexpected("Please setup responses")
        }
        let data = dataResponses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {}
    
    func refreshToken() async throws -> UserToken {
        StreamVideo.mockToken
    }
    
    func update(tokenProvider: @escaping UserTokenProvider) {}
}
