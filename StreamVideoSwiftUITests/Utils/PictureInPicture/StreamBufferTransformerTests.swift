//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest
import CoreGraphics
import StreamWebRTC
@testable import StreamVideoSwiftUI

final class StreamBufferTransformerTests: XCTestCase {

    func testTransformWithNoResizeRequired() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = false
        let sourceBuffer = RTCI420Buffer(
            width: 100,
            height: 100,
            strideY: 100,
            strideU: 50,
            strideV: 50
        )
        let targetSize = CGSize(width: 100, height: 100)

        let resultBuffer = try XCTUnwrap(transformer.transform(sourceBuffer, targetSize: targetSize))

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func testTransformWithResizeRequired() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = true
        let sourceBuffer = RTCI420Buffer(
            width: 200,
            height: 200,
            strideY: 200,
            strideU: 100,
            strideV: 100
        )
        let targetSize = CGSize(width: 50, height: 50)

        let resultBuffer = try XCTUnwrap(transformer.transform(sourceBuffer, targetSize: targetSize))

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func testResizeSizeToFitWithinContainer() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = true
        let sourceBuffer = RTCI420Buffer(
            width: 450,
            height: 225,
            strideY: 450,
            strideU: 225,
            strideV: 225
        )
        let targetSize = CGSize(width: 150, height: 75)

        let resultBuffer = try XCTUnwrap(transformer.transform(sourceBuffer, targetSize: targetSize))

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }
}
