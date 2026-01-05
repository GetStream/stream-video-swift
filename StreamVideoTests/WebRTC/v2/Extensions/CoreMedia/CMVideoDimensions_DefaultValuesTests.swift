//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import CoreMedia
@testable import StreamVideo
import XCTest

final class CMVideoDimensionsDefaultValuesTests: XCTestCase, @unchecked Sendable {

    func test_areaCalculation() {
        let dimensions = CMVideoDimensions(width: 1920, height: 1080)
        XCTAssertEqual(dimensions.area, 1920 * 1080)
    }

    func test_initWithCGSize() {
        let size = CGSize(width: 1920, height: 1080)
        let dimensions = CMVideoDimensions(size)
        XCTAssertEqual(dimensions.width, 1920)
        XCTAssertEqual(dimensions.height, 1080)
    }

    func test_initWithZeroCGSize() {
        let size = CGSize(width: 0, height: 0)
        let dimensions = CMVideoDimensions(size)
        XCTAssertEqual(dimensions.width, 0)
        XCTAssertEqual(dimensions.height, 0)
    }

    func test_initWithNegativeCGSize() {
        let size = CGSize(width: -1920, height: -1080)
        let dimensions = CMVideoDimensions(size)
        XCTAssertEqual(dimensions.width, -1920)
        XCTAssertEqual(dimensions.height, -1080)
    }
}
