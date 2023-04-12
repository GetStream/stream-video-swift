//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class HTTPClient_Mock: @unchecked Sendable, HTTPClient {
    
    var dataResponses = [Data]()
    var requestCounter = 0
    
    func execute(request: URLRequest) async throws -> Data {
        requestCounter += 1
        if dataResponses.isEmpty {
            throw ClientError.Unexpected("Please setup responses")
        }
        return dataResponses.removeFirst()
    }
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {}
    
    func refreshToken() async throws -> UserToken {
        StreamVideo.mockToken
    }
    
    func update(tokenProvider: @escaping UserTokenProvider) {}
}
