//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class MutableRTCStatistics_Tests: XCTestCase, @unchecked Sendable {
    // MARK: - Tests

    func test_init_fromRTCStatistics() {
        let stat = MutableRTCStatistics(
            timestamp: 456_789,
            type: "inbound-rtp",
            values: ["packetsReceived": 321, "codec": "opus"]
        )

        XCTAssertEqual(stat.timestamp, 456_789)
        XCTAssertEqual(stat.type, "inbound-rtp")
        XCTAssertEqual(stat.values["packetsReceived"], RawJSON(321))
        XCTAssertEqual(stat.values["codec"], RawJSON("opus"))
    }

    func test_encode_decode_roundtrip() throws {
        let original = MutableRTCStatistics(
            timestamp: 123.456,
            type: "outbound-rtp",
            values: ["bytesSent": RawJSON(42), "codec": RawJSON("vp8")]
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MutableRTCStatistics.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    func test_decode_fromExtraJSONFields() throws {
        let json = """
        {
            "timestamp": 42.0,
            "type": "remote-candidate",
            "priority": 123456,
            "ip": "192.168.1.10",
            "port": 3478
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MutableRTCStatistics.self, from: json)
        XCTAssertEqual(decoded.timestamp, 42.0)
        XCTAssertEqual(decoded.type, "remote-candidate")
        XCTAssertEqual(decoded.values["priority"], RawJSON(123_456))
        XCTAssertEqual(decoded.values["ip"], RawJSON("192.168.1.10"))
        XCTAssertEqual(decoded.values["port"], RawJSON(3478))
    }

    func test_encode_encodesDynamicKeys() throws {
        let stat = MutableRTCStatistics(
            timestamp: 99,
            type: "test-type",
            values: ["foo": RawJSON("bar"), "baz": RawJSON(17)]
        )
        let encoded = try JSONEncoder().encode(stat)
        let string = String(data: encoded, encoding: .utf8)!
        XCTAssertTrue(string.contains("\"foo\":\"bar\""))
        XCTAssertTrue(string.contains("\"baz\":17"))
    }
}
