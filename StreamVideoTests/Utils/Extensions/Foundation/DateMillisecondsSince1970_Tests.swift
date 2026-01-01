//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class DateMillisecondsSince1970_Tests: XCTestCase, @unchecked Sendable {

    func test_millisecondsSince1970_matchesExpectedMilliseconds() {
        let referenceDate = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        XCTAssertEqual(referenceDate.millisecondsSince1970, 0)

        let oneSecond = Date(timeIntervalSince1970: 1)
        XCTAssertEqual(oneSecond.millisecondsSince1970, 1000)

        let fractional = Date(timeIntervalSince1970: 1.234)
        XCTAssertEqual(fractional.millisecondsSince1970, 1234)
    }

    func test_millisecondsSince1970_isAccurateForKnownTimestamps() {
        let date = Date(timeIntervalSince1970: 1_699_999_999.789) // known timestamp
        let expected = Int64((1_699_999_999.789 * 1000.0).rounded())
        XCTAssertEqual(date.millisecondsSince1970, expected)
    }

    func test_millisecondsSince1970_roundingBehavior() {
        let date = Date(timeIntervalSince1970: 42.4994)
        XCTAssertEqual(date.millisecondsSince1970, 42499)

        let roundedUp = Date(timeIntervalSince1970: 42.5001)
        XCTAssertEqual(roundedUp.millisecondsSince1970, 42500)
    }
}
