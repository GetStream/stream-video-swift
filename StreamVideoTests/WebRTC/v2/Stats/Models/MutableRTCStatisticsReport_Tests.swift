//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class MutableRTCStatisticsReport_Tests: XCTestCase, @unchecked Sendable {

    private lazy var dummyStats: [String: MutableRTCStatistics]! = [
        "stat1": MutableRTCStatistics(
            timestamp: 123,
            type: "typeA",
            values: ["val": RawJSON("abc")]
        ),
        "stat2": MutableRTCStatistics(
            timestamp: 124,
            type: "typeB",
            values: ["num": RawJSON(42)]
        )
    ]

    override func tearDown() {
        dummyStats = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_assignsProperties() {
        let timestamp: TimeInterval = 999
        let report = MutableRTCStatisticsReport(
            timestamp: timestamp,
            statistics: dummyStats
        )
        XCTAssertEqual(report.timestamp, timestamp)
        XCTAssertEqual(report.statistics, dummyStats)
    }

    // MARK: - Encode & Decode

    func test_encodeDecode_roundtrip() throws {
        let original = MutableRTCStatisticsReport(
            timestamp: 321.5,
            statistics: dummyStats
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MutableRTCStatisticsReport.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Decode

    func test_decode_dynamicKeys() throws {
        let json = """
        {
            "timestamp": 555.5,
            "statA": {
                "timestamp": 12,
                "type": "foo",
                "val": "bar"
            },
            "statB": {
                "timestamp": 13,
                "type": "baz",
                "num": 5
            }
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MutableRTCStatisticsReport.self, from: json)
        XCTAssertEqual(decoded.timestamp, 555.5)
        XCTAssertEqual(decoded.statistics["statA"]?.type, "foo")
        XCTAssertEqual(decoded.statistics["statB"]?.type, "baz")
        XCTAssertEqual(decoded.statistics["statA"]?.values["val"], .init("bar"))
        XCTAssertEqual(decoded.statistics["statB"]?.values["num"], .init(5))
    }

    func test_encode_dynamicKeys() throws {
        let report = MutableRTCStatisticsReport(
            timestamp: 999,
            statistics: dummyStats
        )
        let data = try JSONEncoder().encode(report)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertTrue(string.contains("\"stat1\""))
        XCTAssertTrue(string.contains("\"stat2\""))
        XCTAssertTrue(string.contains("\"timestamp\""))
    }
}
