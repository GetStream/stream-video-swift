//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallConfigurationTests: XCTestCase, @unchecked Sendable {

    func test_timeout_shouldReturnProductionTimeouts() {
        let timeout = CallConfiguration.Timeout.production

        XCTAssertEqual(timeout.join, 30)
        XCTAssertEqual(timeout.accept, 10)
        XCTAssertEqual(timeout.reject, 10)
        XCTAssertEqual(timeout.joinInterception, 5)
    }

    func test_timeout_shouldReturnTestingTimeouts() {
        let timeout = CallConfiguration.Timeout.testing

        XCTAssertEqual(timeout.join, 10)
        XCTAssertEqual(timeout.accept, 10)
        XCTAssertEqual(timeout.reject, 10)
        XCTAssertEqual(timeout.joinInterception, 10)
    }
}
