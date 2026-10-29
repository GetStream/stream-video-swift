//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class HTTPClient_Mock: @unchecked Sendable, HTTPClient, DefaultAPITransport {
            
    let decoder = PassthroughJSONDecoder()
    var dataResponses = [Data]()
    var errors = [Error]()
    var requestCounter = 0
    var requests = [Request]()

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
        requests.append(request)
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

// Generated responses are Decodable only, so mocks pass them by an ID.
// Other data decodes as JSON.
final class PassthroughJSONDecoder: JSONDecoder, @unchecked Sendable {
    private let payloads = AllocatedUnfairLock<[UUID: Any]>([:])

    func decodingData(for payload: Any) -> Data {
        let id = UUID()
        payloads.withLock { $0[id] = payload }
        return Data(id.uuidString.utf8)
    }

    override func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let id = UUID(uuidString: String(decoding: data, as: UTF8.self))
        guard let payload = id.flatMap({ id in payloads.withLock { $0.removeValue(forKey: id) } }) else {
            return try JSONDecoder.streamCore.decode(type, from: data)
        }
        guard let payload = payload as? T else {
            throw ClientError.Unexpected("Mocked payload \(payload) is not \(T.self)")
        }
        return payload
    }
}
