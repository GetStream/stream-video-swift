//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ScreenShareAudioFilterGate_Tests: XCTestCase, @unchecked Sendable {

    func test_setActive_forwardsToHandler() {
        let seen = Seen()
        let subject = ScreenShareAudioFilterGate { seen.values.append($0) }

        subject.setActive(true)
        subject.setActive(false)

        XCTAssertEqual(seen.values, [true, false])
    }
}

private final class Seen: @unchecked Sendable {
    var values: [Bool] = []
}
