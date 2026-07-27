//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class JSONDecoder_Tests: XCTestCase, @unchecked Sendable {
    private var decoder: JSONDecoder = .streamCore

    func test_throwsException_whenDecodingDateFromEmptyString() {
        checkDecodingDateThrowException(dateString: "")
    }

    func test_throwsException_whenDecodingDateFromInvalidString() {
        checkDecodingDateThrowException(dateString: "123456")
    }

    func test_decodes_whenDecodingDateWithoutTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2020-09-30T19:51:17",
            year: 2020,
            month: 9,
            day: 30,
            hour: 19,
            minute: 51,
            second: 17
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMilliseconds() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2020-08-24T17:28:04.123Z",
            year: 2020,
            month: 8,
            day: 24,
            hour: 17,
            minute: 28,
            second: 4,
            fractionalSeconds: 123
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithEmptyMilliseconds() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-12-02T15:11:12Z",
            year: 2002,
            month: 12,
            day: 2,
            hour: 15,
            minute: 11,
            second: 12
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T07:12:13-03:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+02:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 8,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusZeroTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusZeroTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13-00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateBefore1970() throws {
        try checkDateIsDecodingToComponents(
            dateString: "1936-10-02T10:12:13Z",
            year: 1936,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMicroseconds() throws {
        let data = json(dateString: "2020-06-09T08:10:40.800912Z").data(using: .utf8)!
        let decoded = try JSONDecoder.streamCore.decode([String: Date].self, from: data)
        let date = try XCTUnwrap(decoded[dateKey])

        XCTAssertEqual(
            date.timeIntervalSince1970,
            1_591_690_240.800_912,
            accuracy: 0.000_001
        )
    }

    // MARK: Helpers

    private let dateKey = "date"

    private func json(dateString: String) -> String {
        "{\"\(dateKey)\":\"\(dateString)\"}"
    }

    private func checkDateIsDecodingToComponents(
        dateString: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        fractionalSeconds: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        // Given
        let dateJson = json(dateString: dateString)
        let data = dateJson.data(using: .utf8)!

        // When
        let decoded: [String: Date] = try decoder.decode([String: Date].self, from: data)

        // Then
        let decodedDate = decoded[dateKey]!

        // Use GMT calendar, to test on GMT+0 timezone
        let components = Calendar.gmtCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: decodedDate
        )

        XCTAssertEqual(components.year, year, file: file, line: line)
        XCTAssertEqual(components.month, month, file: file, line: line)
        XCTAssertEqual(components.day, day, file: file, line: line)
        XCTAssertEqual(components.hour, hour, file: file, line: line)
        XCTAssertEqual(components.minute, minute, file: file, line: line)
        XCTAssertEqual(components.second, second, file: file, line: line)

        if let fractional = fractionalSeconds {
            let nanosecondsInMillisecond = 1_000_000
            let nanos = components.nanosecond!

            var fractionalResult = nanos / nanosecondsInMillisecond
            let modulo = nanos % nanosecondsInMillisecond

            if modulo > nanosecondsInMillisecond / 2 {
                fractionalResult += 1
            }

            XCTAssertEqual(fractionalResult, fractional, file: file, line: line)
        }
    }

    private func checkDecodingDateThrowException(dateString: String, file: StaticString = #filePath, line: UInt = #line) {
        // Given
        let dateJson = json(dateString: dateString)
        let data = dateJson.data(using: .utf8)!

        XCTAssertThrowsError(
            try decoder.decode([String: Date].self, from: data),
            file: file,
            line: line
        )
    }
}
