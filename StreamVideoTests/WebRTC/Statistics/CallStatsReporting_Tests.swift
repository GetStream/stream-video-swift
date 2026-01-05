//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CallStatsReporting_Tests: XCTestCase, @unchecked Sendable {

    func test_callStatsReport_jsonString() throws {
        // Given
        let sampleTimestamp = CFTimeInterval(123_456)
        let sampleType = "inbound-rtp"
        let sampleId = "123"
        let sampleKey = "jitter"
        let sampleValue = NSNumber(value: 0.5)
        let stats = MockStreamStatistics(
            timestamp_us: sampleTimestamp,
            type: sampleType,
            id: sampleId,
            values: [
                sampleKey: sampleValue
            ]
        )
        let report = MockStreamStatisticsReport(stats: [sampleId: stats])
        
        // When
        let jsonString = report.jsonString
        
        // Then
        XCTAssertNotNil(jsonString)
        
        // When
        let data = jsonString?.data(using: .utf8)
        let jsonReports = try JSONDecoder().decode([TestJsonReport].self, from: data!)
        let jsonReport = jsonReports[0]
        
        // Then
        XCTAssertEqual(jsonReport.id, sampleId)
        XCTAssertEqual(jsonReport.jitter, sampleValue.doubleValue)
        XCTAssertEqual(jsonReport.timestamp, sampleTimestamp)
        XCTAssertEqual(jsonReport.type, sampleType)
    }
}

struct TestJsonReport: Codable {
    let timestamp: CFTimeInterval
    let type: String
    let jitter: Double
    let id: String
}
