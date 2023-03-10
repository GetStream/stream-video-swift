//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SignalServer_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        LogConfig.level = .debug
    }

    func test_signalServer_retryingRequest() async throws {
        // Given
        let responses = generateRetryResponses(10)
        let httpClient = MockHTTPClient()
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
        XCTAssert(httpClient.requestCounter == 6)
        XCTAssert(response == nil)
    }
    
    private func generateRetryResponses(_ count: Int) -> [Data] {
        var responses = [Data]()
        for _ in 0..<count {
            responses.append(retryResponse())
        }
        return responses
    }
    
    private func retryResponse() -> Data {
        var error = Stream_Video_Sfu_Models_Error()
        error.shouldRetry = true
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        response.error = error
        return try! response.serializedData()
    }

}
