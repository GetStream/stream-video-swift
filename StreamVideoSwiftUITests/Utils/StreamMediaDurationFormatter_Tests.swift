//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamVideoSwiftUI

final class StreamMediaDurationFormatter_Tests: XCTestCase {

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
