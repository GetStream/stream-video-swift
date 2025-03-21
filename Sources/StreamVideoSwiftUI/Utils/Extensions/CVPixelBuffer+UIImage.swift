//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import Foundation
import UIKit

extension CVPixelBuffer {
    static func build(from uiImage: UIImage) -> CVPixelBuffer? {
        let width = Int(uiImage.size.width)
        let height = Int(uiImage.size.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
            ] as CFDictionary,
            &pixelBuffer
        )

        guard
            let cgImage = uiImage.cgImage,
            status == kCVReturnSuccess,
            let pixelBuffer = pixelBuffer
        else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )

        context?.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        return pixelBuffer
    }
}
#endif
