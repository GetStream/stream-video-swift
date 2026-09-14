//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class VideoConfig_Tests: XCTestCase, @unchecked Sendable {

    func test_init_whenUseLiveCommunicationKitIsNotProvided_defaultsToTrue() {
        let subject = VideoConfig()

        XCTAssertTrue(subject.useLiveCommunicationKit)
    }

    func test_init_whenUseLiveCommunicationKitIsFalse_setsValue() {
        let subject = VideoConfig(useLiveCommunicationKit: false)

        XCTAssertFalse(subject.useLiveCommunicationKit)
    }
}
