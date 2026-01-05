//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CIImage_Resize_Tests: XCTestCase, @unchecked Sendable {

    func testResizeWithAspectRatio() {
        let originalImage = makeImage(of: CGSize(width: 100, height: 50))
        let targetSize = CGSize(width: 200, height: 100)

        guard let resizedImage = originalImage.resize(targetSize) else {
            XCTFail("Resize failed")
            return
        }

        // Check dimensions and aspect ratio
        XCTAssertEqual(resizedImage.extent.width, targetSize.width)
        XCTAssertEqual(resizedImage.extent.height, targetSize.height)
        XCTAssertEqual(resizedImage.extent.width / resizedImage.extent.height, 2.0, accuracy: 0.01)
    }

    // MARK: - Upscale without aspect ratio change

    func testResizeUpscaleWithoutAspectRatioChange() {
        let originalImage = makeImage(of: CGSize(width: 100, height: 50))
        let targetSize = CGSize(width: 200, height: 100)

        guard let resizedImage = originalImage.resize(targetSize) else {
            XCTFail("Resize failed")
            return
        }

        // Check dimensions
        XCTAssertEqual(resizedImage.extent.width, targetSize.width)
        XCTAssertEqual(resizedImage.extent.height, targetSize.height)
    }

    // MARK: - Downscale with aspect ratio

    func testResizeDownscaleWithAspectRatio() {
        let originalImage = makeImage(of: CGSize(width: 200, height: 100))
        let targetSize = CGSize(width: 100, height: 50)

        guard let resizedImage = originalImage.resize(targetSize) else {
            XCTFail("Resize failed")
            return
        }

        // Check dimensions and aspect ratio
        XCTAssertEqual(resizedImage.extent.width, targetSize.width)
        XCTAssertEqual(resizedImage.extent.height, targetSize.height)
        XCTAssertEqual(resizedImage.extent.width / resizedImage.extent.height, 2.0, accuracy: 0.01)
    }

    // MARK: - Performance test

    func testResizePerformance() {
        measure {
            let largeImage = makeImage(of: .init(width: 2000, height: 2000))
            _ = largeImage.resize(CGSize(width: 500, height: 500))
        }
    }

    // MARK: - Private helpers

    private func makeImage(of size: CGSize) -> CIImage {
        .init(image: .make(with: .red, size: size)!)!
    }
}

// MARK: - Private Helpers

extension UIImage {

    fileprivate static func make(
        with color: UIColor,
        size: CGSize
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
