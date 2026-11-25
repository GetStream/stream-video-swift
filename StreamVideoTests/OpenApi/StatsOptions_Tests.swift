//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
@preconcurrency import XCTest

final class StatsOptions_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - decode

    func test_decode_withHLSFields_exposesHLSSwitchAndInterval() throws {
        let subject = try decode(
            hls: ", \"enable_hls_stats\": false, \"reporting_hls_interval_ms\": 5000"
        )

        XCTAssertEqual(subject.enableHlsStats, false)
        XCTAssertEqual(subject.reportingHlsIntervalMs, 5000)
    }

    func test_decode_withoutHLSFields_hasNoHLSSwitchOrInterval() throws {
        let subject = try decode(hls: "")

        XCTAssertNil(subject.enableHlsStats)
        XCTAssertNil(subject.reportingHlsIntervalMs)
    }

    func test_decode_keepsWebRTCFields() throws {
        let subject = try decode(hls: "")

        XCTAssertTrue(subject.enableRtcStats)
        XCTAssertEqual(subject.reportingIntervalMs, 10000)
    }

    // MARK: - Private helpers

    private func decode(hls: String) throws -> StatsOptions {
        let json = """
        {
            "enable_rtc_stats": true,
            "reporting_interval_ms": 10000\(hls)
        }
        """
        return try JSONDecoder.streamCore.decode(
            StatsOptions.self,
            from: Data(json.utf8)
        )
    }
}
