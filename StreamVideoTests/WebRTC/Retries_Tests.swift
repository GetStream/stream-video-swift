//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import WebRTC
import XCTest

final class Retries_Tests: XCTestCase {
    
    let dummyRequest = URLRequest(url: URL(string: "https://test.com")!)
    let dummyData = Data()
    let dummyError = ClientError.NetworkError()
    var dummyState = "dummy"
    
    func test_executeTask_success() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = [dummyData]
        
        // When
        let result = try await executeTask(retryPolicy: .fastAndSimple, task: {
            try await httpClient.execute(request: dummyRequest)
        })
        
        // Then
        XCTAssert(result == dummyData)
        XCTAssert(httpClient.requestCounter == 1)
    }
    
    func test_executeTask_successAfterRetry() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        httpClient.errors = [dummyError]
        httpClient.dataResponses = [dummyData]
        
        // When
        let result = try await executeTask(retryPolicy: .fastAndSimple, task: {
            try await httpClient.execute(request: dummyRequest)
        })
        
        // Then
        XCTAssert(result == dummyData)
        XCTAssert(httpClient.requestCounter == 2)
    }
    
    func test_executeTask_maxRetries() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        
        // When
        do {
            _ = try await executeTask(retryPolicy: .fastAndSimple, task: {
                try await httpClient.execute(request: dummyRequest)
            })
            XCTFail("Task should fail")
        } catch {
            // Then
            XCTAssert(httpClient.requestCounter == 4)
        }
    }
    
    func test_executeTask_runPrecondition() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let condition = { self.dummyState == "dummy" }
        httpClient.errors = [dummyError]
        httpClient.dataResponses = [dummyData]
        
        // When
        let result = try await executeTask(retryPolicy: .fastCheckValue(condition), task: {
            try await httpClient.execute(request: dummyRequest)
        })
        
        // Then
        XCTAssert(result == dummyData)
        XCTAssert(httpClient.requestCounter == 2)
    }
    
    func test_executeTask_failedPrecondition() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let condition = { self.dummyState == "dummy" }
        httpClient.errors = [dummyError]
        httpClient.dataResponses = [dummyData]
        
        // When
        dummyState = "changed"
        do {
            _ = try await executeTask(retryPolicy: .fastCheckValue(condition), task: {
                try await httpClient.execute(request: dummyRequest)
            })
            XCTFail("Task should fail")
        } catch {
            // Then
            XCTAssert(httpClient.requestCounter == 1)
        }
    }
    
    func test_executeTask_neverGiveUp5Attempts() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        httpClient.errors = [dummyError, dummyError, dummyError, dummyError]
        httpClient.dataResponses = [dummyData]
        let condition = { self.dummyState == "dummy" }
        
        // When
        let result = try await executeTask(
            retryPolicy: .neverGonnaGiveYouUp(condition),
            task: {
            try await httpClient.execute(request: dummyRequest)
        })
        
        // Then
        XCTAssert(result == dummyData)
        XCTAssert(httpClient.requestCounter == 5)
    }

}
