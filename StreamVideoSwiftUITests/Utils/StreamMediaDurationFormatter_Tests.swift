//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class StreamMediaDurationFormatter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: StreamMediaDurationFormatter! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - format

    func test_format_durationIsLessThanAnHour_returnsExpectedResult() {
        XCTAssertEqual(subject.format(1800), "30:00")
    }

    func test_format_durationIsMoreThanAnHour_returnsExpectedResult() {
        XCTAssertEqual(subject.format(7290), "02:01:30")
    }
}
