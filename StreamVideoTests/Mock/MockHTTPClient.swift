//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockHTTPClient: @unchecked Sendable, HTTPClient {
    
    var dataResponses = [Data]()
    
    func execute(request: URLRequest) async throws -> Data {
        if dataResponses.isEmpty {
            throw ClientError.Unexpected("Please setup responses")
        }
        return dataResponses.removeFirst()
    }
    
    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {}
}
