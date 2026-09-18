//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class VideoConfig_Tests: XCTestCase, @unchecked Sendable {

    func test_init_whenUseLiveCommunicationKitIsNotProvided_defaultsToFalse() {
        let subject = VideoConfig()

        XCTAssertFalse(subject.useLiveCommunicationKit)
    }

    func test_init_whenUseLiveCommunicationKitIsTrue_setsValue() {
        let subject = VideoConfig(useLiveCommunicationKit: true)

        XCTAssertTrue(subject.useLiveCommunicationKit)
    }
}
