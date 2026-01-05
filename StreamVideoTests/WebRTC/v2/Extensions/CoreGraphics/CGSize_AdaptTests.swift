//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
@testable import StreamVideo
import XCTest

final class CGSizeAdaptTests: XCTestCase, @unchecked Sendable {

    func test_adjustedToFit_withZeroSize_returnsMinimumSafeSize() {
        let size = CGSize(width: 0, height: 0)
        let adjustedSize = size.adjusted(toFit: 100)
        XCTAssertEqual(adjustedSize, CGSize(width: 16, height: 16))
    }

    func test_adjustedToFit_withNegativeSize_returnsMinimumSafeSize() {
        let size = CGSize(width: -10, height: -10)
        let adjustedSize = size.adjusted(toFit: 100)
        XCTAssertEqual(adjustedSize, CGSize(width: 16, height: 16))
    }

    func test_adjustedToFit_withZeroMaxSize_returnsMinimumSafeSize() {
        let size = CGSize(width: 100, height: 100)
        let adjustedSize = size.adjusted(toFit: 0)
        XCTAssertEqual(adjustedSize, CGSize(width: 16, height: 16))
    }

    func test_adjustedToFit_withWiderAspectRatio_returnsAdjustedSize() {
        let size = CGSize(width: 1920, height: 1080)
        let adjustedSize = size.adjusted(toFit: 100)
        XCTAssertEqual(adjustedSize, CGSize(width: 100, height: 58))
    }

    func test_adjustedToFit_withTallerAspectRatio_returnsAdjustedSize() {
        let size = CGSize(width: 1080, height: 1920)
        let adjustedSize = size.adjusted(toFit: 100)
        XCTAssertEqual(adjustedSize, CGSize(width: 58, height: 100))
    }

    func test_adjustedToFit_withSquareAspectRatio_returnsAdjustedSize() {
        let size = CGSize(width: 100, height: 100)
        let adjustedSize = size.adjusted(toFit: 50)
        XCTAssertEqual(adjustedSize, CGSize(width: 50, height: 50))
    }

    func test_adjustedToFit_ensuresSafeMultiples() {
        let size = CGSize(width: 1920, height: 1080)
        let adjustedSize = size.adjusted(toFit: 99)
        XCTAssertEqual(adjustedSize, CGSize(width: 100, height: 56))
    }
}
