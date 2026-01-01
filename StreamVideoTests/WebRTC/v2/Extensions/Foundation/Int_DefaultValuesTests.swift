//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class IntDefaultValuesTests: XCTestCase, @unchecked Sendable {

    func test_defaultFrameRate() {
        XCTAssertEqual(Int.defaultFrameRate, 30)
    }

    func test_defaultScreenShareFrameRate() {
        XCTAssertEqual(Int.defaultScreenShareFrameRate, 25)
    }

    func test_maxBitrate() {
        XCTAssertEqual(Int.maxBitrate, 1_000_000)
    }

    func test_maxSpatialLayers() {
        XCTAssertEqual(Int.maxSpatialLayers, 3)
    }

    func test_maxTemporalLayers() {
        XCTAssertEqual(Int.maxTemporalLayers, 1)
    }
}
