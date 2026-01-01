//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SignalServer_Tests: XCTestCase, @unchecked Sendable {
    
    override func setUp() {
        super.setUp()
    }

    func test_signalServer_retryingRequest() async throws {
        // Given
        let responses = generateRetryResponses(10)
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = responses
        let signalServer = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: "key1",
            hostname: "test.com",
            token: StreamVideo.mockToken.rawValue
        )
        let testRequest = Stream_Video_Sfu_Signal_SetPublisherRequest()
        
        // When
        let response = try? await signalServer.setPublisher(setPublisherRequest: testRequest)
        
        // Then
        XCTAssertEqual(httpClient.requestCounter, 6)
        XCTAssertNil(response)
    }
    
    func test_signalServer_nonRetryingRequest() async throws {
        // Given
        var responses = generateRetryResponses(2)
        responses.append(response(shouldRetry: false))
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = responses
        let signalServer = Stream_Video_Sfu_Signal_SignalServer(
            httpClient: httpClient,
            apiKey: "key1",
            hostname: "test.com",
            token: StreamVideo.mockToken.rawValue
        )
        let testRequest = Stream_Video_Sfu_Signal_SetPublisherRequest()
        
        // When
        let response = try? await signalServer.setPublisher(setPublisherRequest: testRequest)
        
        // Then
        XCTAssertEqual(httpClient.requestCounter, 3)
        XCTAssertNil(response)
    }
    
    private func generateRetryResponses(_ count: Int) -> [Data] {
        var responses = [Data]()
        for _ in 0..<count {
            responses.append(response())
        }
        return responses
    }
    
    private func response(shouldRetry: Bool = true) -> Data {
        var error = Stream_Video_Sfu_Models_Error()
        error.shouldRetry = shouldRetry
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        response.error = error
        return try! response.serializedData()
    }

}
