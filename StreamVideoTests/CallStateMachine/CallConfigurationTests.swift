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
    }
}
