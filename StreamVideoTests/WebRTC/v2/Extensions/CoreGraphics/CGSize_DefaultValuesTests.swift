//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import CoreMedia
@testable import StreamVideo
import XCTest

final class CGSizeDefaultValuesTests: XCTestCase, @unchecked Sendable {

    func test_defaultFullSize() {
        XCTAssertEqual(CGSize.full, CGSize(width: 1280, height: 720))
    }

    func test_defaultHalfSize() {
        XCTAssertEqual(CGSize.half, CGSize(width: 640, height: 480))
    }

    func test_defaultQuarterSize() {
        XCTAssertEqual(CGSize.quarter, CGSize(width: 480, height: 360))
    }

    func test_areaCalculation() {
        let size = CGSize(width: 1920, height: 1080)
        XCTAssertEqual(size.area, 1920 * 1080)
    }

    func test_initWithCMVideoDimensions() {
        let videoDimensions = CMVideoDimensions(width: 1920, height: 1080)
        let size = CGSize(videoDimensions)
        XCTAssertEqual(size, CGSize(width: 1920, height: 1080))
    }

    func test_initWithZeroCMVideoDimensions() {
        let videoDimensions = CMVideoDimensions(width: 0, height: 0)
        let size = CGSize(videoDimensions)
        XCTAssertEqual(size, CGSize(width: 0, height: 0))
    }

    func test_initWithNegativeCMVideoDimensions() {
        let videoDimensions = CMVideoDimensions(width: -1920, height: -1080)
        let size = CGSize(videoDimensions)
        XCTAssertEqual(size, CGSize(width: -1920, height: -1080))
    }
}
