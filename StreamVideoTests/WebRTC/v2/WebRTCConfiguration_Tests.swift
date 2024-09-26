//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCConfigurationTests: XCTestCase {

    func test_timeout_shouldReturnProductionTimeouts() {
        let timeout = WebRTCConfiguration.Timeout.production

        XCTAssertEqual(timeout.authenticate, 10)
        XCTAssertEqual(timeout.connect, 10)
        XCTAssertEqual(timeout.join, 10)
        XCTAssertEqual(timeout.migrationCompletion, 10)
    }
}
