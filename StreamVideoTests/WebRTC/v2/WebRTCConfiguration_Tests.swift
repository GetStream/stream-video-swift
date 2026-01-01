//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCConfigurationTests: XCTestCase, @unchecked Sendable {

    func test_timeout_shouldReturnProductionTimeouts() {
        let timeout = WebRTCConfiguration.Timeout.production

        XCTAssertEqual(timeout.authenticate, 30)
        XCTAssertEqual(timeout.connect, 30)
        XCTAssertEqual(timeout.join, 30)
        XCTAssertEqual(timeout.migrationCompletion, 10)
        XCTAssertEqual(timeout.publisherSetUpBeforeNegotiation, 2)
    }
}
