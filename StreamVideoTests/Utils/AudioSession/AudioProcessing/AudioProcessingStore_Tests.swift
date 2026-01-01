//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AudioProcessingStore_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject

    private lazy var subject: AudioProcessingStore! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_setAudioFilter_updatesActiveFilter() async {
        XCTAssertNil(subject.activeAudioFilter)

        let filter = MockAudioFilter(id: "af-1")
        subject.setAudioFilter(filter)

        await fulfillment { self.subject.activeAudioFilter?.id == "af-1" }
    }
}
