//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest
import CoreGraphics
import StreamWebRTC
import StreamSwiftTestHelpers
import SnapshotTesting
@testable import StreamVideoSwiftUI

final class StreamBufferTransformerTests: XCTestCase {

    // MARK: - transform(_: RTCI420Buffer, targetSize: CGSize)

    func test_RTCI420Buffer_TransformWithNoResizeRequired() throws {
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

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func test_RTCI420Buffer_TransformWithResizeRequired() throws {
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

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func test_RTCI420Buffer_ResizeSizeToFitWithinContainer() throws {
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

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    // MARK: - transform(_: RTCCVPixelBuffer, targetSize: CGSize)

    func test_RTCCVPixelBuffer_TransformWithNoResizeRequired() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = false
        let sourceBuffer = RTCCVPixelBuffer(
            pixelBuffer: try XCTUnwrap(
                CVPixelBuffer.make(
                    with: .init(width: 100,height: 100),
                    pixelFormat: kCVPixelFormatType_32ARGB
                )
            )
        )
        let targetSize = CGSize(width: 100, height: 100)

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func test_RTCCVPixelBuffer_TransformWithResizeRequired() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = true
        let sourceBuffer = RTCCVPixelBuffer(
            pixelBuffer: try XCTUnwrap(
                CVPixelBuffer.make(
                    with: .init(width: 200, height: 200),
                    pixelFormat: kCVPixelFormatType_32ARGB
                )
            )
        )
        let targetSize = CGSize(width: 50, height: 50)

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    func test_RTCCVPixelBuffer_ResizeSizeToFitWithinContainer() throws {
        var transformer = StreamBufferTransformer()
        transformer.requiresResize = true
        let sourceBuffer = RTCCVPixelBuffer(
            pixelBuffer: try XCTUnwrap(
                CVPixelBuffer.make(
                    with: .init(width: 450, height: 225),
                    pixelFormat: kCVPixelFormatType_32ARGB
                )
            )
        )
        let targetSize = CGSize(width: 150, height: 75)

        let resultBuffer = try XCTUnwrap(transformer.transformAndResizeIfRequired(sourceBuffer, targetSize: targetSize)?.imageBuffer)

        // Assert that no resize occurred, and the output size matches the target size.
        XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), Int(targetSize.height))
    }

    // MARK: - transform(_: CVPixelBuffer)

    func testTransformPixelBuffer() {
        // Given
        let transformer = StreamBufferTransformer()
        let image = UIImage(named: "test", in: Bundle(for: type(of: self)), with: nil)!
        let buffer = buffer(from: image)!

        // When
        let sampleBuffer = transformer.transform(buffer)!
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let converted = self.convert(cmage: ciimage)

        // Then)
        assertSnapshot(matching: converted, as: .image(precision: precision))
    }

    // MARK: - Private Helpers

    private func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(image.size.width),
            Int(image.size.height),
            kCVPixelFormatType_32ARGB,
            attrs, &pixelBuffer
        )
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    private func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
}
