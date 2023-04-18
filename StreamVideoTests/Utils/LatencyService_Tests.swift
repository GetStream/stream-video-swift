//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class LatencyService_Tests: XCTestCase {

    func test_latencyService_availableMeasurements() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = [Data()]
        let latencyService = LatencyService(httpClient: httpClient)
        
        // When
        let datacenterResponse = DatacenterResponse(
            coordinates: .init(latitude: 0.0, longitude: 0.0),
            latencyUrl: "http://test.com",
            name: "test"
        )
        let measurements = await latencyService.measureLatency(for: datacenterResponse)
        
        // Then
        XCTAssert(measurements.contains(Float(Int.max)) == false)
    }
    
    func test_latencyService_oneFailureFallback() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        httpClient.dataResponses = [Data()]
        let latencyService = LatencyService(httpClient: httpClient)
        
        // When
        let datacenterResponse = DatacenterResponse(
            coordinates: .init(latitude: 0.0, longitude: 0.0),
            latencyUrl: "http://test.com",
            name: "test"
        )
        let measurements = await latencyService.measureLatency(
            for: datacenterResponse,
            tries: 2
        )
        
        // Then
        XCTAssert(measurements.count == 2)
        XCTAssert(measurements[1] == Float(Int.max))
    }
}
